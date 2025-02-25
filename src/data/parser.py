import itertools
import os
import plotly.express as px
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import math
import numpy as np
import re

from scipy import stats

from pathlib import Path

data_order = {}

sas_data_folder = ENTER_DATA_PATH_TO_CSV_FILE_HERE

csv_file_name = "all_iterations.csv"

COLUMNS = {"Machine": str, "Run": int, "Time": float, "Framerate": float, "FPS_Satisfaction": float, 
           "Camera_Zoom": float, "Smoothing": bool, 
           "Number_Of_Enemies_Per_Second": float, "Number_Of_Enemies_Min": float, "Number_Of_Enemies_Max": float, 
           "Enemy_Size_Range_Min": float, "Enemy_Size_Range_Max": float, 
           "Enemy_Size_Min": float, "Enemy_Size_Max": float, 
           "Enemy_Velocity_Range_Min": float, "Enemy_Velocity_Range_Max": float,
           "Enemy_Velocity_Min": float, "Enemy_Velocity_Max": float, 
           "Enemy_Sight": float, "Enemy_Sight_Min": float, "Enemy_Sight_Max": float,
           "Score": float, "Player_Size": float, "Number_Of_Enemies": int, 
           "Zoom_Adaptations": int, "Enemy_Adaptations": int}

def iterate_subfolders(root_dir):
   
    subfolders = {}

    try:
        _, dirnames, _ = next(os.walk(root_dir)) 
        for dirname in dirnames:
            subfolder_path = os.path.join(root_dir, dirname)
            subfolders[dirname] = subfolder_path + "\\"
    except StopIteration:
        pass  

    return subfolders

def writeDataFromFile(data, folderName, file, i):
        
        while True:
                data_to_add = [folderName, i]
                data_line = file.readline()

                if(data_line == ""):
                        break;
                
                data_line = data_line.strip().split(",")

                for v in data_line:
                        match = re.match(r"\(([^)]+)\)", v)  # Match (x y) format
                        if match:
                                x, y = match.group(1).split()  # Split by space
                                data_to_add.extend([x, y])  # Store as separate columns
                        else:
                                data_to_add.append(v)  # Store normal values as is

                if len(data_to_add) != len(COLUMNS):
                        print(f"Skipping malformed row in {file.name}: {data_to_add}")
                        continue  # Skip this row

                data.append(data_to_add)

def setTypes(df):
        for colName, colType in COLUMNS.items():
                print(f"Setting {colName} to {colType}")
                df[colName] = df[colName].astype(colType)

        return df

def initDF():
        data = []
        readFromFile = False
        if os.path.isfile(sas_data_folder + csv_file_name):
                #Read in the file. 
                readFromFile = True
                data = pd.read_csv(sas_data_folder + csv_file_name)
        else:
                
                subfolders = iterate_subfolders(sas_data_folder)
                for folderName, folderPath in subfolders.items():
                        print(f"Reading files from {folderName}")
                        for i in range(0, 100):
                                file_path = folderPath + "Run " + str(i) + ".txt"
                                
                                if not os.path.exists(file_path):
                                        continue
                                
                                f = open(file_path, 'r')

                                writeDataFromFile(data, folderName, f, i)
                               

        df = pd.DataFrame(np.array(data), columns = COLUMNS.keys())

        df = setTypes(df)      

        if not readFromFile:
               
                df.to_csv(sas_data_folder + csv_file_name, index=False)

        return df

def getMachines(df):
        return df['Machine'].unique()

def getMachineCombinations(df):
        machines = getMachines(df)

        allCombinations = list(itertools.combinations(machines, 2))

        return allCombinations

def displayPValueGraph(df):
        allCombinations = getMachineCombinations(df)

        pValuesDF = pd.DataFrame(columns=["Pair", "pValue", "Adaptation"])

        for _, v in enumerate(allCombinations):
                dataset1 = df[df['Machine'] == v[0]]
                dataset2 = df[df['Machine'] == v[1]]
                
                enemyAdaptations1 = dataset1.groupby("Run")["Enemy_Adaptations"].max()
                enemyAdaptations2 = dataset2.groupby("Run")["Enemy_Adaptations"].max()

                enemy_pval = stats.mannwhitneyu(enemyAdaptations1, enemyAdaptations2).pvalue
                print(f"p value for Enemy Adaptations with pair {v[0]} and {v[1]}: {enemy_pval:.4f}")
                pValuesDF = pd.concat([pValuesDF, pd.DataFrame({"Pair": [f"{v[0]} vs {v[1]}"], "pValue": [enemy_pval], "Adaptation": ["Enemy Adaptations"]})], ignore_index=True)

        for _, v in enumerate(allCombinations):
                dataset1 = df[df['Machine'] == v[0]]
                dataset2 = df[df['Machine'] == v[1]]
                
                zoomAdaptations1 = dataset1.groupby("Run")["Zoom_Adaptations"].max()
                zoomAdaptations2 = dataset2.groupby("Run")["Zoom_Adaptations"].max()

                zoom_pval = stats.mannwhitneyu(zoomAdaptations1, zoomAdaptations2).pvalue

                print(f"p value for Zoom Adaptations with pair {v[0]} and {v[1]}: {zoom_pval:.4f}")
                
                pValuesDF = pd.concat([pValuesDF, pd.DataFrame({"Pair": [f"{v[0]} vs {v[1]}"], "pValue": [zoom_pval], "Adaptation": ["Zoom Adaptations"]})], ignore_index=True)

        plt.figure(figsize=(10, 6))
        sns.barplot(data=pValuesDF, x="Pair", y="pValue", hue="Adaptation", palette="Set2")
        plt.yscale("log")

        # Labels and Formatting
        plt.axhline(y=0.05, color='r', linestyle='--', label="Significance Threshold (0.05)")
        plt.xticks(rotation=45, ha="right")
        plt.xlabel("Computer Pair")
        plt.ylabel("p-value")
        plt.title("p-values for Enemy and Zoom Adaptations")
        plt.legend()
        plt.tight_layout()
        plt.show()

def displayAdaptations(df):

        df_melted = df.melt(id_vars=['Machine'], value_vars=['Zoom_Adaptations', 'Enemy_Adaptations'],
                     var_name='Adaptation Type', value_name='Count')

        plt.figure(figsize=(8, 6))

        sns.boxplot(x='Machine', y='Count', hue='Adaptation Type', data=df_melted, palette={'Zoom_Adaptations': '#1f77b4', 'Enemy_Adaptations': '#ff7f0e'})

        plt.xlabel('Configuration')
        plt.ylabel('Adaptation Count')
        plt.title('Adaptations per Machine')

        plt.tight_layout()

        plt.show()


def displayViolations(df):
        latituderuns = df[df['Machine'] == 'Latitude']

        latitude_groupbyruns = latituderuns.groupby("Run")

        violations = latitude_groupbyruns.apply(
        lambda g: (
                ((g["FPS_Satisfaction"] == 0) & (g["FPS_Satisfaction"].shift(1) != 0)).sum() +
                ((g["Framerate"] == 0) & (g["Framerate"].shift(1) != 0)).sum()
        ),
        include_groups=False 
        ).reset_index(name='Violations')

def createUtilityValues(df):
        df['utilZoom'] = np.clip((df['Framerate'] - 850)/(1400-850), 0, 1)

        df['utilNumberEnemies'] = (df['Number_Of_Enemies_Per_Second'] - df['Number_Of_Enemies_Min']) / (df['Number_Of_Enemies_Max'] - df['Number_Of_Enemies_Min'])

        return df;


def createUtilityValuesGraph(df):
        fig, ax = plt.subplots(figsize=(6, 6))
        sns.lineplot(data=df, x="utilNumberEnemies", y="FPS_Satisfaction", hue="Machine", errorbar="sd", ax=ax)

        ax.set_xlabel("Utility Value E.d")
        ax.set_ylabel("Utility Value G.d")
        ax.set_title("Utility Values E.d and G.d")

        ax.set_aspect(1)

        plt.show()

        fig, ax = plt.subplots(figsize=(6, 6))
        sns.lineplot(data=df, x="utilNumberEnemies", y="FPS_Satisfaction", errorbar="sd", ax=ax)

        ax.set_xlabel("Utility Value E.d")
        ax.set_ylabel("Utility Value G.d")
        ax.set_title("Utility Values E.d and G.d")

        ax.set_aspect(1)

        plt.show()

df = initDF()

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)


displayPValueGraph(df)

displayAdaptations(df)

displayViolations(df)

createUtilityValues(df)
createUtilityValuesGraph(df)
