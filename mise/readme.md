
#####
#####
# Example of a PowerShell task that uses an environment variable for input
[tasks.greet]
hide = true
shell = "pwsh -NoProfile -Command"
usage = '''
arg "<name>" help="Name to greet"
'''
run = '''
Write-Host "Hello, $env:usage_name -"
'''

# Example of a cmd task that uses an environment variable for input
[tasks.greet2]
hide = true
usage = '''
arg "<name>" help="Name to greet"
'''
run = '''
echo "Hello, %usage_name% -"
'''
