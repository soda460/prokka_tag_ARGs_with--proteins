#!/usr/bin/env python
import os
import glob
import argparse
import shutil
from pathlib import Path
from subprocess import Popen, PIPE

def get_files(start_dir):
	""" Given a directory, make a list of specific files
	    This function will find all files recursively.
	"""
	files = []
	for filename in Path(start_dir).glob('**/plasmid*.fasta'):
		files.append(str(filename))
	return files

def ask_before_removing(folder):
	""" Given a directory, ask before removing its content.
	"""
	if os.path.exists(folder):
		if input("The specified output folder" + folder + 
			" already exists. Are you sur you want to remove it ? (y/n)") == "y":
			shutil.rmtree(folder)
		else:
			print('Exit!')
			exit()


if __name__ == "__main__":

	""" The program will find assembly files and will prepare prokka commands""" 

	# Construct the argument parser
	ap = argparse.ArgumentParser()

	# Add the arguments to the parser
	ap.add_argument("-i", "--input", required=True, help="PATH of the folder containing the assemblies files ")
	ap.add_argument("-o", "--output", required=True, help="PATH of the output folder ")
	ap.add_argument("-p", "--proteins", required=False, help="*Full* PATH of the fasta file of trusted proteins to first annotate from (PROKKA) ")
		
	# Parsing arguments
	args = vars(ap.parse_args())	# args a dict
	input_folder = args['input']
	output_folder = args['output']
	trusted_proteins =  args['proteins']

	# Check the existence of the specidied output folder
	# and overwrite its content if the answer is 'yes'
	ask_before_removing(output_folder)

	f_list = get_files(input_folder)



	# Step 1 fastaReHeader.pl in parallel

	''' This block prepare a list of commands for the Perl script
		fastaReHeader.pl with the three arguments required.
		It also create a directory named 'input' in the output directory specified
		by the --output option. Inside  'input/' are also created
		directories for each strain_names where will be written the relabeled fasta files.
	'''
	cmds_list = []    # a list of commands for fastaReHeader.pl
	for file_name in f_list:
		strain_name = file_name.split('/')[-2]
		fastaReHeader_out = output_folder + '/input/'
		if not os.path.exists(fastaReHeader_out + strain_name):
			os.makedirs(fastaReHeader_out + strain_name)	
		cmds_list.append(['./fastaReHeader.pl', file_name, strain_name, fastaReHeader_out])

	procs_list = [Popen(cmd, stdout=PIPE, stderr=PIPE) for cmd in cmds_list]
	# put it in function dude!
	# Execute all process and report error messages in stdout
	for proc in procs_list:
		proc.wait()
		stdout = proc.stdout.read()
		stderr = proc.stderr.read()
		if stdout:
			print (stdout)
		if stderr:
			print (stderr)
	
	
	
	# Step 2 prokka in parallel

	''' This block prepare a list of commands for prokka ...
	'''
	cmds_list = []    # a list of commands for prokka
	os.mkdir(output_folder + '/output/') # prokka will create folders for each strains
	for file_name in f_list:
		strain_name = file_name.split('/')[-2]
		molecule_name = (file_name.split('/')[-1]).replace('.fasta', '')
		prokka_out = output_folder + '/output/' + strain_name
		cmds_list.append(['prokka', '--outdir', prokka_out,
							'--prefix', molecule_name,
							'--cpus', '1', '--addgenes', '--force',
							'--genus', 'bidon', '--species', 'bidon',
							'--strain', 'dangerous strain',
							#'--proteins', trusted_proteins,
						file_name, '> /dev/null'])
	
	procs_list = [Popen(cmd, stdout=PIPE, stderr=PIPE) for cmd in cmds_list]
	
	# put it in function dude!
	# Execute all process and report error messages in stdout
	for proc in procs_list:
		proc.wait()
		stdout = proc.stdout.read()
		stderr = proc.stderr.read()
		if stdout:
			print (stdout)
		if stderr:
			print (stderr)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	



	
