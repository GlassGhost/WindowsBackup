#Configuring for Dual Boot using unaltered MBR from Win7 install

Basically you use linux to setup grub boot for the partition & save the linux.bin file onto your C drive

    sudo grub-install --root-directory=/media/LINUX /dev/sda3
    dd if=/dev/sda3 of=/media/WINDOWS7/linux.bin bs=512 count=1

all you need to do is type this in your windows admin console:

    bcdedit /create /d Linux /application BOOTSECTOR

Get the id from the previous line and place it wherever you see 12345

    bcdedit /set {12345} device partition=c:
    bcdedit /set {12345} path \linux.bin
    bcdedit /displayorder {12345} /addlast
    bcdedit /timeout 4

___
## Greater Detail of the above

after installing grub onto your linux partition, which would look something like:

    sudo grub-install --root-directory=/media/LINUX /dev/sda3

Use dd to write the first 512 bytes of your Linux partition to a file on your windows 7 "C partition"

    dd if=/dev/sda3 of=/media/WINDOWS7/linux.bin bs=512 count=1

Then copy this file onto your Windows 7 partition and continue the rest of this guide there

After rebooting into Windows 7, use BCDEdit to add an entry to Windows 7’s BCD store.
dministrative privileges are required to use BCDEdit, so navigate through Start->All Programs->Accessories, Right-click on Command Prompt and select “Run as administrator.” Okay, now let’s start by creating an entry for our Linux distribution. Note here that you are free to choose another entry name if desired:

    bcdedit /create /d Linux /application BOOTSECTOR

BCDEdit will return an alphanumeric identifier for this entry that I will refer to as {ID} in the remaining steps. You’ll need to replace {ID} by the actual returned identifier. An example of {ID} is {d7294d4e-9837-11de-99ac-f3f3a79e3e93}. Next, let’s specify which partition hosts a copy of the linux.bin file:
The 1st 2 lines setup the path to our linux.bin file, 3rd line adds an entry to the displayed menu at boot time, and the 4th line sets how long the menu choices will be displayed:

    bcdedit /set {ID} device partition=c:
    bcdedit /set {ID} path \linux.bin
    bcdedit /displayorder {ID} /addlast
    bcdedit /timeout 30

That’s it! Now reboot and you will be presented with menu where you can choose to boot to Windows 7 or Linux. When you choose Linux, you’ll be taken to the GRUB menu where you can choose to continue booting your Linux distribution or return to the previous menu.

On a final note, if at any time you want to eliminate the Linux menu option simply delete the BCD store entry you created using the following command:

    bcdedit /delete {ID}

also to get a list of IDs in your bcd booter simply run:

    bcdedit /enum
