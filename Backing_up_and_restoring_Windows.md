Backing up and restoring Windows
================================

**Objective**: 
--------------
Create 3 files under 3-4gb that can later be used to restore the windows re-install in 10 mins or less:

 - restore_windows.sh
 - ComputerName_DriveName.boot.xz
 - ComputerName_OSname.ntfsclone.xz

Programs needed:
----------------
 - a linux live cd preferably a new one
 - most live cd's contain:
    * dd
    * fdisk
    * ntfsclone
    * xz

_________________
## Backup Process

This assumes you have an MBR partition scheme and have [Windows installed to the 1st partition](#windowsinstallprocess)
and that you have followed the "[BEFORE YOU backup ANY Windows partition](#beforeyoubackupanywindowspartition)" procedure.

`/dev/hdX` = device name gotten from list of devices gotten from with `fdisk -l`
`/dev/hdX1` = partition name gotten from list of devices gotten from with `fdisk -l`

To backup boot sector with no compression:  
`dd bs=1M count=1 if=/dev/hdX of=/path/to/ComputerName_DriveName.boot`  

To backup a partition with no compression:  
`ntfsclone -s /dev/hdX1 -o /path/to/ComputerName_OSname.ntfsclone`  

To Compress any file after backup(You can change the number after the letter 'T'
correspondingly, to the # of cores or threads on your processor):  
`nice -19 xz -v9ekC sha256 -T 2 /path/to/uncompressed/file`  

Example of a run I did on my quad core rig(30 mins to create 500mb restore file!!):

    glas@K53TA:~$ xz -v9ekC sha256 -T 4 '/media/DATA/Shared/Images/E4300_WinXP.ntfsclone'
    /media/DATA/Shared/Images/E4300_WinXP.ntfsclone (1/1)
    100 % 502.8 MiB / 1,388.7 MiB = 0.362 813 KiB/s 29:08             

To backup boot sector AND compress it with xz on highest compression with sha256 checksums, at the same time:  
`dd bs=1M count=1 if=/dev/hdX | nice -19 xz -v9ekC sha256 > /path/to/ComputerName_DriveName.boot.xz`

(OPTIONAL)To backup a partition with compression **DURING** backup process:  
`ntfsclone -s /dev/hdX1 -o - | nice -19 xz -v9ekC sha256 -T 2 > /path/to/ComputerName_OSname.ntfsclone.xz`

I would not suggest Compressing the partition during the backup, as it takes a while even on
faster machines. Decompressing isn't really stressful on ANY machine.


______________________
## Restoration Process

To restore a partition with xz compression:

    xz -dc /path/to/ComputerName_OSname.ntfsclone.xz | ntfsclone -rO /dev/hdX1 -

To restore a partition with no compression:

    ntfsclone -rO /dev/hdX /path/to/ComputerName_OSname.ntfsclone

AFTER you have backed up OR restored the partition you may then use gparted or
some other partition editor to grow the NTFS volume as you wish.  
NOTE: after you do this when windows asks to scan the drive DON'T let it.

When restoring boot sector from previous backup, to leave other partitions unaffected,  
The 463rd to 512th bytes in the boot sector contain the "partition info" of all the other partitions must remain unchanged

    dd count=1 bs=512 if=/dev/hdX of=/path/to/external_drive/temp.boot
    dd if=/path/to/ComputerName_DriveName.boot of=/dev/hdX
    dd if=/path/to/external_drive/temp.boot of=/dev/hdX
    dd count=1 bs=462 if=/path/to/ComputerName_DriveName.boot of=/dev/hdX

__________________________
## Windows install Process

NOTE: this is untested for Windows 8 but should work on any Windows install
provided it doesn't edit the partition scheme.

Start Linux. CLEAR the drive and create a 16gb partition as the 1st partition,
this can be done with gparted. Close Linux. Then install Windows to this
partition.

It doesn't matter if you download Windows Install ISO from an illegitimate site as long as:  
Before you burn it you test to make certain it's Sha1sum matches, the Official Microsoft released Sha1 for the ISO file in question:  
[Windows 7](https://msdn.microsoft.com/en-us/subscriptions/downloads/default.aspx#searchTerm=&ProductFamilyId=350&Languages=en&PageSize=100&PageIndex=0&FileId=0)  
[Windows 8](https://msdn.microsoft.com/en-us/subscriptions/downloads/default.aspx#searchTerm=&ProductFamilyId=545&Languages=en&PageSize=100&PageIndex=0&FileId=0)  
For instance I searched "Windows 7 Premium Service Pack 1 x64 English" & found under it's details it's sha1 was `6C9058389C1E2E5122B7C933275F963EDF1C07B9`
Then google search'd for the sha1 of and found a download or torrent.

Again, DO NOT BURN the iso until AFTER you have made certain that the sha1 is matching the Official Microsoft released Sha1 for the ISO file in question.  
Either through the linux `sha1sum` command or through [Microsoft's checksum tool](http://www.microsoft.com/en-us/download/details.aspx?id=11533)


### BEFORE YOU backup ANY Windows partition
ALWAYS make sure you have used regedit to delete all the non-empty entries in:  
`HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices`  
This MUST be done on the shut-down right before a backup, in order to allow booting on a replacement hard-drive.

### (optional)Reduce your "restore-file"'s size by an additional 1-4gb

System Properties->Advanced->Performance Settings->Advanced->Change->No Paging File->set->ok->ok  
then reboot  
System Properties->Advanced->Performance Settings->Advanced->Change->System Managed Size->set->ok->ok  
Then remove the mounted devices entry in regedit as described earlier, then shutdown.  
THEN DO NOT BOOT INTO WINDOWS UNTIL AFTER YOU HAVE BACKED IT UP (or you have to
do this whole section again if you don't want the extra 1-4gb in your backup file, from the page-file)

Also the file may still exist but is now safe to delete, you may have to even
manually mount the drive in linux and delete the pagefile.sys AND "hyberfile.sys"
if either of them exist, before you back up or they may STILL be there. <--- Just
about requires special voodoo magic to work around Microsoft retardation.


Vista or WIN7 extra 100mb partition problem
-------------------------------------------
During Microsoft Windows Setup, if you create a new partition on a clean HDD (no
partitions), or delete all partitions and then create a new one - from the
Partition screen in Setup, Win7 will create an 100MB boot partition, and you
can't stop it/cancel it. That is why the guide says to make the Partition with
Linux before Windows Installation.

___________
## MBR INFO

    MBR SECTOR NAME	BYTES
    code area	440(max. 446)
    disk signature (optional)	4
    Usually nulls; 0x0000	2
    Table of primary partitions	64(Four 16-byte entries, IBM partition table scheme)
    MBR signature;0xAA55	2
    
    MBR, total size: 446 + 64 + 2 =	512

Moving NTFS partitions
----------------------
Strongly advised not to be done. this how-to is thanx to Michael Dominok @ http://www.dominok.net/en/it/en.it.clonexp.html

Now, the boot-sectors of the newly cloned partition have to be modified. The partition(s) in front of the new ones have to be "skipped". This is done by inserting an offset into the partitions boot-sector. But first we've got to determine where they start. "fdisk -ul /dev/hda" shows:

       Device Boot Start End Blocks Id System
    /dev/hda1 * 63 40965749 20482843+ 7 HPFS/NTFS
    /dev/hda2 40965750 81979694 20506972+ 7 HPFS/NTFS
    /dev/hda3 81979695 122993639 20506972+ 7 HPFS/NTFS
    /dev/hda4 122993640 181582694 29294527+ 5 Extended
    /dev/hda5 122993703 181582694 29294496 83 Linux

The interesting values are listed in the "Start"-column but have to be converted into hexadecimal and rearranged in order. `printf "0x%llx\n" 40965750` `printf`s 40965750 in hexadecimal format `0x2711676`
"printf "%x" 40965750" would have done, too.
The hexadecimal value `2711676` has to be rearranged further. The digits have to skewed by pairs following this method:

     0xABCD EFGH => GHEF CDAB
     0x031f 9f3e => 3E9F 1F03

For "2711676" this results in "76167102"
Since we've got 4 pairs to skew but only 7 digits available we simply add a leading 0. This is as neutral in the hexadecimal system as it is in the more familiar decimal system.
Now "76167102" has to be inserted into hda2s boot-sector. That's done with "hexedit /dev/hda2"
Move the cursor to position "0x1c" and type in "76 16 71 02", then save&quit with "<STRG>-X"
Use the same procedure for hd3. 

This is simply done by running the Vista/7 startup repair.
Enter the installation DVD -> Select repair and follow the wizard.


other commands
--------------

    sudo mkdir /mnt/susv3
    sudo mount -osize=100m tmpfs /mnt/susv3 -t tmpfs
    cd '/mnt/susv3' 
    unlzma -ck '/home/glas/Comp Sci/C/susv3.tlz' | tar xvf -
