#!/usr/bin/python

import sys, getopt, codecs

def main(argv):
	inputfile = ''
	outputfile = ''
	try:
		opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
	except getopt.GetoptError:
		print 'po2cfg.py -i <inputfile> -o <outputfile>'
		sys.exit(2)
	for opt, arg in opts:
		if opt == '-h':
			print 'po2cfg.py -i <inputfile> -o <outputfile>'
			sys.exit()
		elif opt in ("-i", "--ifile"):
			inputfile = arg
		elif opt in ("-o", "--ofile"):
			outputfile = arg
	if not inputfile or not outputfile:
		print 'po2cfg.py -i <inputfile> -o <outputfile>'
		sys.exit(2)
		
	input = codecs.open(inputfile, 'r', 'utf-8')
	output = codecs.open(outputfile, 'w', 'utf-8')
	
	# write header
	output.write('# SOME DESCRIPTIVE TITLE.\n')
	output.write('# Copyright (C) YEAR THE PACKAGE\'S COPYRIGHT HOLDER\n')
	output.write('# This file is distributed under the same license as the PACKAGE package.\n')
	output.write('# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.\n')
	output.write('msgid \"\"\nmsgstr \"\"\n')
	output.write('\"Project-Id-Version: PACKAGE VERSION\\n\"\n')
	output.write('\"Report-Msgid-Bugs-To: \\n\"\n')
	output.write('\"POT-Creation-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n')
	output.write('\"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n\"\n')
	output.write('\"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n\"\n')
	output.write('\"Language-Team: LANGUAGE <LL@li.org>\\n\"\n')
	output.write('\"Language: \\n\"\n')
	output.write('\"MIME-Version: 1.0\\n\"\n')
	output.write('\"Content-Type: text/plain; charset=UTF-8\\n\"\n')
	output.write('\"Content-Transfer-Encoding: 8bit\\n\"\n\n')

	line = input.readline()
	while line != '':
		if not line.startswith('#'):
			namevalue = line.split('=')
			if len(namevalue) > 1:
				name = namevalue[0].strip(' \"\n')
				value = namevalue[1].strip(' \"\n')
				if name and value:
					output.write('msgid \"' + name + '\"\nmsgstr \"' + value + '\"\n\n')
		line = input.readline()
	input.close()
	output.close()

if __name__ == "__main__":
	main(sys.argv[1:])
