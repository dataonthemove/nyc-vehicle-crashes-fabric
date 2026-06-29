######################################################################################
# Enironment varables / stuff
######################################################################################

############ System vars
  # To display the values of all the environment variables, type:
Get-ChildItem Env:
# single var

Get-ChildItem Env:\COMPUTERNAME 


# Powershell Variables 
Get-Variable | more     # All Powershell Variables can be got here. Key ones below

    ######### Environment Related  Automatic Variables
    $PSVersionTable.PSVersion	# Determine the engine version. 
    
    $profile 	# path to your personal autostart script
    $home 	    # path to the place where PowerShell lives.  	
    $PSHOME 	# path to your personal profile folder.

    ##################### Scripting Related Automatic Variables
    $Host 	#Eval to a object that represents the current host application. Sample output:
    
    ##################### Arguments and Script Name
    $Args 	#A array of the argument received by your function or script or block of code.
    $Pwd 	#Returns a path object that represents the full path of the current dir. Iterators; Misc
    $? 		#Returns True if last operation succeeded, else False.
    $Error 	#Returns a array of objects, representing the recent errors. $Error[0] is the most recent, $Error[1] is the error before that, etc.


######################################################################################
# High-freq "Help" stuff
######################################################################################
Update-help # downloads from online (was erroring on certain cmdlet)

############## Get-Help  (My Alias: help)
    # *About* Get-Help  
        Get-Help  Get-Help
        Get-Help | Get-Member  #Object model foret-Help
    # Using Get-Help for other cmdlets  (verbose)
        Get-Help Copy-Item | more
        Get-Help Copy-Item -Examples | more
        Get-Help Copy-Item -Detailed | more  # includes parmeters!
############## Get-Command  (My Alias: cmd)
    # *About*  Get-Command  
        Get-Help  Get-Command -Examples
        Get-Command | Get-Member
    # Using Get-Command  
        Get-Command -Noun *service*  
        Get-Command -Type Cmdlet 
############## Get-Member (My Alias: mbr)
    # About Get-Member
        Get-Help  Get-Member -Examples
    # Using Get-Member for other cmdlets
        Copy-Item | Get-Member
        Get-Member


######################################################################################
# Course-PowerShell Getting Started (Pluralsight)
######################################################################################

# ------------- Introduction to PowerShell 

# ------------- PowerShell Basics
Get-verb  | more
Get-verb  -verb set | format-list
Get-verb  -group security  
Get-Alias -Definition *service*

# ------------- Gathering Information with PowerShell
<# 
Method:
    Get-Command
    Get-Help
    Get-Member
 #>

Get-Command -verb *get*  -noun *ip*    # can only be used alone or together
Get-Command  *mea* -Type cmdlet       # otherwise use other params like this
 
help get-counter -Examples
help get-eventlog -Examples

help get-computerinfo       # local computer only
help get-computerinfo -Examples       
get-computerinfo -property "os*"
get-computerinfo  -property "*mem*"
get-computerinfo  -property "*csname*"

# Mainly for folders and files
Get-ChildItem -Path  C:\Users\1admin\Documents\ -Recurse -Force
Get-ChildItem -Path  C:\Users\1admin\Documents\  | Where-Object Extension -EQ '.txt'
Get-ChildItem -Path  C:\Users\1admin\Documents\  | Where-Object Extension -EQ '.txt'|format-table directory, name, lastwritetime


# These similar to DOS commands
Copy-Item
Move-Item



# ------------- Remoting with PowerShell
# Variables
help Get-Variable
Get-Variable | more

# Credential used with varable 
$credential = Get-Credential
# PowerShell credential request prompts
# Then can retreave cred
$credential

#Get-ComputerInfo in var
$computername = Get-ComputerInfo -property csname
$computername

# DESKTOP-HS7P1FI 

# ------------- Building a User Inventory Script with PowerShell
Get-ExecutionPolicy -list
set-ExecutionPolicy  -list





# ------------- Next Steps with PowerShell


######################################################################################
# Course-
######################################################################################




######################################################################################
# Course-
######################################################################################
