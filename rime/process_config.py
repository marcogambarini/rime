# -*- coding: utf-8 -*-
"""
Created on Mon Oct  2 16:28:48 2023

@author: byers

File within which to configure the settings and working directories
To be imported at start of each file run using 
from process_config import *

"""
# =============================================================================
# process_config.py
# =============================================================================
import os
from configparser import RawConfigParser
import argparse

# Check if a configuration file has been provided as command-line argument
parser = argparse.ArgumentParser(
    description="Run the RIME emulator",
    epilog="Use -c to specify the location of a configuration file",
    formatter_class=argparse.RawDescriptionHelpFormatter
)
parser.add_argument("-c", action="store_true",
                    help="Set a configuration file")
parser.add_argument("conffile", nargs=1,
                    help="Path to the configuration file")
args = parser.parse_args()

print(args.conffile[0])

# Read configuration file, if provided
if args.conffile:
    conf = RawConfigParser()
    conf.read(args.conffile[0])

def read_setting(sect_name, var_name, default_val):
    if (args.c and conf.has_section(sect_name)):
        return conf[sect_name].get(var_name)
    else:
        return default_val

# Regional aggregation of outputs ('R10' or 'COUNTRIES')
region = read_setting("settings", "output_region_agg", "R10")
# Base name for output files 
input_scenarios_name = read_setting("settings", "input_scenarios_name", "testrun")
# Temperature variable to look for in the input files
temp_variable = read_setting("settings", "temp_variable",
    "AR6 climate diagnostics|Surface Temperature (GSAT)|MAGICCv7.5.3|50.0th Percentile"
)
# Input source of processed climate data by ssp/year/variable/reg
folder_input_climate = read_setting("folders", "folder_input_climate",
    "/home/marco/cmcc/committed/rime-data/aggregated_inputs/"
)
# Input IAMC scenarios file, must have a temperature variable called temp_variable
fname_input_scenarios = read_setting("folders", "fname_input_scenarios",
    f"test_data/true_input_scenarios.xlsx"
)
# Output directory
wd2 = read_setting("folders", "folder_output", "test_outputs/")


# Run and environment settings
user = "byers"
env = "pc"

# git_path = f"C:\\users\\{user}\\Github\\"
git_path = f"C:\\Github\\"

table_output_format = f"table_output_|_{region}.csv"


yr_start = 2020
yr_end = 2100


# Dask settings
num_workers = 24  # Number of workers. More workers creates more overhead
parallel = True # Uses Dask in processing the IAMC scenarios


caution_checks = True


# =============================================================================
# %% Working directories
# =============================================================================


yaml_path = "indicator_params.yml"
landmask_path = git_path + "climate_impacts_processing\\landareamaskmap0.nc"
kg_class_path = git_path + "climate_impacts_processing\\kg_class.nc"

if env == "pc":
    # Main working directory
    #wd = f"C:\\Users\\{user}\\IIASA\\ECE.prog - Documents\\Research Theme - NEXUS\\Hotspots_Explorer_2p0\\"
    wd = "./"
    wd_input = f"P:\\watxene\\ISIMIP_postprocessed\\cse\\"  # Input data branch
    # Directory of table files to read as input
    wdtable_input = "table_output\\"

    output_dir = f"{wd2}aggregated_region_datafiles\\"

    fname_input_climate = f"{folder_input_climate}*_{region}*.nc"

    # Directory of map files to read as input
    impact_data_dir = f"{wd}\\data\\4_split_files_for_geoserver"
    # impact_data_dir = f"{wd_input}split_files"


# =============================================================================
# %% From process-iamc_scenarios_gwl.py
# =============================================================================

year_resols = [5]

ssp_meta_col = "Ssp_family"  # meta column name of SSP assignment


output_folder_tables = f"{wd2}"
output_folder_maps = f"{wd2}"

prefix_indicator = "Climate impacts|RIME|"


few_scenarios = False
very_few_scenarios = False
# few_variables = True
testing = False
test = "" if testing == False else "para"
lvaris = 200


# %% =============================================================================
# from interpolate_maps.py
# =============================================================================

# impact data settings

indicators = ["cdd", "precip"]
ftype = "score"  # score
interpolation = 0.01


# scenario data settings
years = range(2015, 2101, 5)
scenarios = {"AIM/CGE 2.0": "SSP1-26", "GCAM 5.3": "SSP_SSP5"}
sspdic = {1.0: "ssp1", 2.0: "ssp2", 3.0: "ssp3", 4.0: "ssp4", 5.0: "ssp5"}


# =============================================================================
# %% Functions
# =============================================================================
