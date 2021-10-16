# VS-Code-Tasks

> ⚠️ No longer maintained. Archived and kept for reference only. ⚠️

## How to use VS Code Tasks to simplify writing and testing z/OS Unix Shell scripts

As a developer, I want to write and execute a z/OS Unix shell script in VS Code without leaving the editor.

## Pre-requisites:
- VS Code
- Zowe Explorer
- Zowe CLI

## Current workflows
1. Zowe Explorer USS + ISPF 
    - I open VS Code, go to Zowe Explorer, and create a new file under USS Tree
    - I do my coding and save the file, which is automatically written back to z/OS Unix
    - I go to TSO -> OMVS, find my file, the run it 

2. Zowe Explorer USS + DATA SETS + JOBS
    - I open VS Code, go to Zowe Explorer, and create a new file under USS Tree
    - I do my coding and save the file, which is automatically written back to z/OS Unix
    - I go to my JCL collection in DATA SETS tree, find my BPXBATCH job, alter it to point to my file, then submit it
    - I then go to the JOBS Tree, look for the job, and check the spool files 
    > Keeps me in the editor, but still not happy with moving to different places and clicking around

3. Zowe Explorer USS + SSH ?!?
    - I open VS Code, go to Zowe Explorer, and create a new file under USS Tree
    - I do my coding and save the file, which is automatically written back to z/OS Unix
    - TBD: next steps  

4. Zowe Explorer USS + VS Code Tasks
    - I open VS Code, go to Zowe Explorer, and create a new file under USS Tree
    - I do my coding and save the file, which is automatically written back to z/OS Unix
    - I run my custom task by pressing a personalized key bind to submit a remote pre-defined BPXBATCH JCL that runs my shell script
    - output is displayed in the embedded console
    > This looks better! :smile:
