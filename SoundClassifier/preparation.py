#!/usr/bin/env python3

# BEGIN SC_python1
import os
import shutil
import pandas as pd

import os.path as path

# BEGIN SC_python_inner
# Configure as required

esc_path = '/Users/desplesda/Work/third-party/ESC-50/'

input_classes_filename = path.join(esc_path, 'meta/esc50.csv')
sounds_directory = path.join(esc_path, 'audio/')
output_directory = path.join(esc_path, 'classes/')
classes_to_include =  [
    'dog', 'rooster', 'pig', 'cow', 'frog', 'cat', 'hen', 
    'insects', 'sheep', 'crow'
]

# whether to use whole ESC-50 dataset or lesser-restricted ESC-10 subset
include_unlicensed = True 
# END SC_python_inner

# Make output directory
try:
    os.makedirs(output_directory)
except OSError:
    if not os.path.isdir(output_directory):
        raise

# Make class directories within it
for class_name in classes_to_include:
    class_directory = output_directory + class_name + '/'
    try:
        os.makedirs(class_directory)
    except OSError:
        if not os.path.isdir(class_directory):
            raise

# Go through CSV to sort audio into class directories
classes_file = pd.read_csv(
    input_classes_filename,
    encoding='utf-8',
    header = 'infer'
)

# format: filename, fold, target, category, esc10, src_file, take
for line in classes_file.itertuples(index = False):
    if include_unlicensed or line[4] == True:
        file_class = line[3]

        if file_class in classes_to_include:
            file_name = line[0]
            file_src = sounds_directory + file_name
            file_dst = output_directory + file_class + '/' + file_name
            try:
                print("{} -> {}".format(file_src, file_dst))
                shutil.copy2(file_src, file_dst)
            except IOError as e:
                print("Error: {}".format(e))
                raise
# END SC_python1

