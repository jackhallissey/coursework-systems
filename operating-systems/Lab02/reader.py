import os

print("I am a Python program!")

if not os.path.exists("/tmp/mypipe"):
    os.mkfifo("/tmp/mypipe", 0o600)

# open the pipe
with open("/tmp/mypipe") as inpipe:
    # read the contents of the pipe and print to screen
    print(inpipe.read())