@echo off

@REM Dev org alias should not be empty
if [%1] == [] (
    echo You should pass scratch org alias as the first param
    exit 0
)

set ORG_ALIAS=%1

call sf project deploy start -c -o %ORG_ALIAS%
call sf apex run -f scripts/MO_Data_Creation.apex -o %ORG_ALIAS%