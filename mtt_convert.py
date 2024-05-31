#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Script to convert Minetest *.tr files to *.po and vice-versa.
#
# Copyright (C) 2023 Wuzzy
# License: LGPLv2.1 or later (see LICENSE file for details)

from __future__ import print_function
import os, fnmatch, re, shutil, errno
from sys import argv as _argv
from sys import stderr as _stderr

# Name of directory to export *.po files into
DIRNAME = "poconvert"

SCRIPTNAME = "mtt_convert"
VERSION = "0.1.0"

MODE_PO2TR = 0
MODE_TR2PO = 1

# comment to mark the section of old/unused strings
comment_unused = "##### not used anymore #####"

# Running params
params = {"recursive": False,
    "help": False,
    "verbose": False,
    "po2tr": False,
    "tr2po": False,
    "folders": [],
}
# Available CLI options
options = {
    "po2tr": ['--po2tr', '-P'],
    "tr2po": ['--tr2po', '-T'],
    "recursive": ['--recursive', '-r'],
    "help": ['--help', '-h'],
    "verbose": ['--verbose', '-v'],
}

# Strings longer than this will have extra space added between
# them in the translation files to make it easier to distinguish their
# beginnings and endings at a glance
doublespace_threshold = 80

pattern_tr = re.compile(r'(.*?[^@])=(.*)')
pattern_name = re.compile(r'^name[ ]*=[ ]*([^ \n]*)')
pattern_tr_filename = re.compile(r'\.tr$')
pattern_tr_language_code = re.compile(r'.*\.([a-zA-Z]+)\.tr$')
pattern_po_language_code = re.compile(r'(.*)\.po$')

def set_params_folders(tab: list):
    '''Initialize params["folders"] from CLI arguments.'''
    # Discarding argument 0 (tool name)
    for param in tab[1:]:
        stop_param = False
        for option in options:
            if param in options[option]:
                stop_param = True
                break
        if not stop_param:
            params["folders"].append(os.path.abspath(param))

def set_params(tab: list):
    '''Initialize params from CLI arguments.'''
    for option in options:
        for option_name in options[option]:
            if option_name in tab:
                params[option] = True
                break

def print_help(name):
    '''Prints some help message.'''
    print(f'''SYNOPSIS
    {name} [OPTIONS] [PATHS...]
DESCRIPTION
    {', '.join(options["help"])}
        prints this help message
    {', '.join(options["po2tr"])}
        convert from *.po to *.tr files
    {', '.join(options["tr2po"])}
        convert from *.tr to *.po files
    {', '.join(options["recursive"])}
        run on all subfolders of paths given
    {', '.join(options["verbose"])}
        add output information''')


def main():
    '''Main function'''
    set_params(_argv)
    set_params_folders(_argv)
    if params["help"]:
        print_help(_argv[0])
    else:
        mode = None
        if params["po2tr"] and not params["tr2po"]:
            mode = MODE_PO2TR
        elif params["tr2po"] and not params["po2tr"]:
            mode = MODE_TR2PO
        else:
            print("You must select a conversion mode (--po2tr or --tr2po)")
            exit(1)
        # Add recursivity message
        print("Running ", end='')
        if params["recursive"]:
            print("recursively ", end='')
        # Running
        if len(params["folders"]) >= 2:
            print("on folder list:", params["folders"])
            for f in params["folders"]:
                if params["recursive"]:
                    run_all_subfolders(mode, f)
                else:
                    update_folder(mode, f)
        elif len(params["folders"]) == 1:
            print("on folder", params["folders"][0])
            if params["recursive"]:
                run_all_subfolders(mode, params["folders"][0])
            else:
                update_folder(mode, params["folders"][0])
        else:
            print("on folder", os.path.abspath("./"))
            if params["recursive"]:
                run_all_subfolders(mode, os.path.abspath("./"))
            else:
                update_folder(mode, os.path.abspath("./"))

#attempt to read the mod's name from the mod.conf file or folder name. Returns None on failure
def get_modname(folder):
    try:
        with open(os.path.join(folder, "mod.conf"), "r", encoding='utf-8') as mod_conf:
            for line in mod_conf:
                match = pattern_name.match(line)
                if match:
                    return match.group(1)
    except FileNotFoundError:
        if not os.path.isfile(os.path.join(folder, "modpack.txt")):
            folder_name = os.path.basename(folder)
            # Special case when run in Minetest's builtin directory
            if folder_name == "builtin":
                return "__builtin"
            else:
                return folder_name
        else:
            return None
    return None

# A series of search and replaces that massage a .po file's contents into
# a .tr file's equivalent
def process_po_file(text):
    if params["verbose"]:
        print(f"Processing PO file ...")
    # escape '@' signs except those followed by digit 1-9
    text = re.sub(r'(@)(?![1-9])', "@@", text)
    # escape equals signs
    text = re.sub(r'=', "@=", text)
    # The first three items are for unused matches
    text = re.sub(r'^#~ msgid "', "", text, flags=re.MULTILINE)
    text = re.sub(r'"\n#~ msgstr ""\n"', "=", text)
    text = re.sub(r'"\n#~ msgstr "', "=", text)
    # clear comment lines
    text = re.sub(r'^#.*\n', "", text, flags=re.MULTILINE)
    # converting msg pairs into "=" pairs
    text = re.sub(r'^msgid "', "", text, flags=re.MULTILINE)
    text = re.sub(r'"\nmsgstr ""\n"', "=", text)
    text = re.sub(r'"\nmsgstr "', "=", text)
    # various line breaks and escape codes
    text = re.sub(r'"\n"', "", text)
    text = re.sub(r'"\n', "\n", text)
    text = re.sub(r'\\"', '"', text)
    text = re.sub(r'\\n', '@n', text)
    # remove header text
    text = re.sub(r'=Project-Id-Version:.*\n', "", text)
    # remove leading whitespace and double-spaced lines
    text = text.lstrip()
    oldtext = ''
    while text != oldtext:
        oldtext = text
        text = re.sub(r'\n\n', '\n', text)
    return text

def generate_po_header(textdomain, language):
    if textdomain == "__builtin":
        project_id = "Minetest builtin component"
    else:
        project_id = "Minetest textdomain " + textdomain
    # fake version number
    project_version = "x.x.x"
    project_id_version = project_id + " " + project_version
    header = """msgid ""
msgstr ""
"Project-Id-Version: """+project_id_version+"""\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: \\n"
"PO-Revision-Date: \\n"
"Last-Translator: \\n"
"Language-Team: \\n"
"Language: """ + language + """\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"Plural-Forms: \\n"
"X-Generator: """+SCRIPTNAME+" "+VERSION+"""\\n"

"""
    return header

def escape_for_tr(text):
    # Temporarily replace " and @@ with ASCII ESC char + another character
    # so they don't conflict with the *.tr escape codes
    text = re.sub(r'"', "\033q", text)
    text = re.sub(r'@@', "\033d", text)

    # unescape *.tr special chars
    text = re.sub(r'@n', '\\\\n\"\n\"', text)
    text = re.sub(r'@=', "=", text)

    # Undo the ASCII escapes
    # Restore \033d to @, not @@ because that's another *.tr escape
    text = re.sub("\033d", "@", text)
    text = re.sub("\033q", '\\"', text)

    return text

# Convert .tr to .po or .pot
# If language is the empty string, will create a template
def process_tr_file(text, textdomain, language):
    if params["verbose"]:
        print(f"Processing TR file ... (textdomain={textdomain}; language={language})")
    stext = ""

    # write header
    stext = generate_po_header(textdomain, language) + stext

    # ignore everything after the special line marking unused strings
    unusedMatch = re.search("\n" + comment_unused, text)
    if (unusedMatch != None):
        text = text[0:unusedMatch.start()]

    # match strings and write in PO-style
    strings = re.findall(r'^(.*(?<!@))=(.*)$', text, flags=re.MULTILINE)
    for s in strings:
        source = s[0]
        source = escape_for_tr(source)

        # Is language is empty string, caller wants a template,
        # so translation is left empty
        translation = ""
        if language != "":
            translation = s[1]
            translation = escape_for_tr(translation)

        stext = stext + 'msgid \"' + source + '\"\n'
        stext = stext + 'msgstr \"' + translation + '\"\n'
        stext = stext + '\n'

    return stext

# Go through existing .tr files and, if a .po file for that language
# *doesn't* exist, convert it and create it.
def process_tr_files(folder, modname):
    for root, dirs, files in os.walk(os.path.join(folder, 'locale')):
        for name in files:
            language_code = None
            if name == 'template.txt':
                language_code = ""
            else:
                code_match = pattern_tr_language_code.match(name)
                if code_match == None:
                    continue
                language_code = code_match.group(1)

            po_name = None
            if language_code == None:
                continue
            elif language_code != "":
                po_name = f'{language_code}.po'
            else:
                po_name = "template.pot"
            mkdir_p(os.path.join(root, DIRNAME))
            po_file = os.path.join(root, DIRNAME, po_name)
            fname = os.path.join(root, name)
            with open(fname, "r", encoding='utf-8') as tr_file:
                if params["verbose"]:
                    print(f"Importing translations from {name}")
                # Convert file contents to *.po syntax
                text = process_tr_file(tr_file.read(), modname, language_code)
                with open(po_file, "wt", encoding='utf-8') as po_out:
                    po_out.write(text)

# Go through existing .po files and, if a .tr file for that language
# *doesn't* exist, convert it and create it.
# The .tr file that results will subsequently be reprocessed so
# any "no longer used" strings will be preserved.
# Note that "fuzzy" tags will be lost in this process.
def process_po_files(folder, modname):
    for root, dirs, files in os.walk(os.path.join(folder, 'locale')):
        for name in files:
            code_match = pattern_po_language_code.match(name)
            if code_match == None:
                continue
            language_code = code_match.group(1)
            tr_name = f'{modname}.{language_code}.tr'
            tr_file = os.path.join(folder, 'locale', tr_name)
            fname = os.path.join(root, name)
            with open(fname, "r", encoding='utf-8') as po_file:
                if params["verbose"]:
                    print(f"Importing translations from {name}")
                # Convert file contents to *.tr syntax
                text = process_po_file(po_file.read())
                # Add textdomain at top
                text = f'# textdomain: {modname}' + '\n' + text
                with open(tr_file, "wt", encoding='utf-8') as tr_out:
                    tr_out.write(text)

# from https://stackoverflow.com/questions/600268/mkdir-p-functionality-in-python/600612#600612
# Creates a directory if it doesn't exist, silently does
# nothing if it already exists
def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

# Gets strings from an existing translation file
# returns both a dictionary of translations
# and the full original source text so that the new text
# can be compared to it for changes.
# Returns also header comments in the third return value.
def import_tr_file(tr_file):
    dOut = {}
    text = None
    header_comment = None
    if os.path.exists(tr_file):
        with open(tr_file, "r", encoding='utf-8') as existing_file :
            # save the full text to allow for comparison
            # of the old version with the new output
            text = existing_file.read()
            existing_file.seek(0)
            # a running record of the current comment block
            # we're inside, to allow preceeding multi-line comments
            # to be retained for a translation line
            latest_comment_block = None
            for line in existing_file.readlines():
                line = line.rstrip('\n')
                if line.startswith("###"):
                    if header_comment is None and not latest_comment_block is None:
                        # Save header comments
                        header_comment = latest_comment_block
                        # Strip textdomain line
                        tmp_h_c = ""
                        for l in header_comment.split('\n'):
                            if not l.startswith("# textdomain:"):
                                tmp_h_c += l + '\n'
                        header_comment = tmp_h_c

                    # Reset comment block if we hit a header
                    latest_comment_block = None
                    continue
                elif line.startswith("#"):
                    # Save the comment we're inside
                    if not latest_comment_block:
                        latest_comment_block = line
                    else:
                        latest_comment_block = latest_comment_block + "\n" + line
                    continue
                match = pattern_tr.match(line)
                if match:
                    # this line is a translated line
                    outval = {}
                    outval["translation"] = match.group(2)
                    if latest_comment_block:
                        # if there was a comment, record that.
                        outval["comment"] = latest_comment_block
                    latest_comment_block = None
                    dOut[match.group(1)] = outval
    return (dOut, text, header_comment)

# Updates translation files for the mod in the given folder
def update_mod(mode, folder):
    modname = get_modname(folder)
    if modname is not None:
        if mode == MODE_TR2PO:
            print(f"Converting TR files for {modname}")
            process_tr_files(folder, modname)
        elif mode == MODE_PO2TR:
            print(f"Converting PO files for {modname}")
            process_po_files(folder, modname)
        else:
            print("ERROR: Invalid mode provided in update_mod()")
            exit(1)
    else:
        print(f"\033[31mUnable to find modname in folder {folder}.\033[0m", file=_stderr)
        exit(1)

# Determines if the folder being pointed to is a mod or a mod pack
# and then runs update_mod accordingly
def update_folder(mode, folder):
    is_modpack = os.path.exists(os.path.join(folder, "modpack.txt")) or os.path.exists(os.path.join(folder, "modpack.conf"))
    if is_modpack:
        subfolders = [f.path for f in os.scandir(folder) if f.is_dir() and not f.name.startswith('.')]
        for subfolder in subfolders:
            update_mod(mode, subfolder)
    else:
        update_mod(mode, folder)
    print("Done.")

def run_all_subfolders(mode, folder):
    for modfolder in [f.path for f in os.scandir(folder) if f.is_dir() and not f.name.startswith('.')]:
        update_folder(mode, modfolder)


main()
