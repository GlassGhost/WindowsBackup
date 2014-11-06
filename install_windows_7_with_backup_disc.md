==Backing up and restoring Windows==
tools needed:
	a linux live cd preferably a new one
	most live cd's contain:
	ntfsclone
	dd
	xz or gzip not necessary if you don't care about storage space
result 3 files under 3-4gb that can be used to restore the windows install in 10 mins or less:
	restore_windows.sh
	ComputerName_DriveName.boot.xz
	ComputerName_OSname.ntfsclone.xz

To make a backup disc for windows you just need to know 2 commands;
dd & ntfsclone

CLEAR the drive and create a 12.5gb partition as the 1st partition, this can be done with gparted. Then install Windows to this partition.

where:   /path/to/ComputerName_DriveName.boot = path and name of backup file
         /dev/hdX = device name
print list of devices with "fdisk -l"

To backup boot sector:
	dd bs=1M count=1 if=/dev/hdX of=/path/to/ComputerName_DriveName.boot
To restore a boot sector:
	dd if=/path/to/ComputerName_DriveName.boot of=/dev/hdX

To backup a partition with no compression:
	ntfsclone -s /dev/hdX -o /path/to/ComputerName_OSname.ntfsclone
To restore a partition with no compression:
	ntfsclone -rO /dev/hdX /path/to/ComputerName_OSname.ntfsclone

After you have backed up or restored the partition you may then use gparted to grow the NTFS volume as you wish.
NOTE: after you do this when windows asks to scan the drive DON'T let it.

====BEFORE YOU backup ANY Windows partition.====
ALWAYS make sure you have used regedit to delete all the non-empty entries in:
"HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices"
This MUST be done on the shut-down right before a backup, in order to allow booting on another hard-drive.

==== (optional) Reduce your "restore-file"'s size by 1-4gb ====
System Properties->Advanced->Performance Settings->Advanced->Change->No Paging File->set->ok->ok
then reboot
System Properties->Advanced->Performance Settings->Advanced->Change->System Managed Size->set->ok->ok
Then remove the mounted devices entry in regedit as described earlier, then shutdown.
THEN DO NOT BOOT INTO WINDOWS UNTIL AFTER YOU HAVE BACKED IT UP (or you have to do this whole section again if you don't want the extra 1-4gb in your backup file, from the page-file)

Also the file may still exist but is now safe to delete, you may have to even manually mount the drive in linux and delete the pagefile.sys AND "hyberfile.sys" if either of them exist, before you back up or they may STILL be there. <--- Just about requires special voodoo magic to work around Microsoft retardation.

==Backing up and restoring Windows with compression==
I've had trouble compressing, not decompressing with xz on older hardware as it is too demanding on the machine. If you want a smaller file size you may have to backup with no compression then transfer the file to a stronger machine and compress it later with:
	nice -19 xz -v9ekC sha256 -T 2 /path/to/uncompressed/ComputerName_OSname.ntfsclone
To restore a partition with xz compression:
	xz -dc /path/to/ComputerName_OSname.ntfsclone.xz | ntfsclone -rO /dev/hdX -

also if you have more than 2 cores or threads on your processor you can change the number after the letter 'T' correspondingly, here is a example of a run I actually did on my quad core rig:
glas@K53TA:~$ xz -v9ekC sha256 -T 4 '/media/DATA/Shared/Images/E4300_WinXP.ntfsclone'
/media/DATA/Shared/Images/E4300_WinXP.ntfsclone (1/1)
  100 %     502.8 MiB / 1,388.7 MiB = 0.362   813 KiB/s      29:08             

500mb restore file!!

==how to compress during backup process==
I would not suggest compressing during the backup, unless the computer is at least dual core > 2.0ghz , as it takes a while even on faster machines. Decompressing isn't really stressful on any machine.
To backup a partition with xz on highest compression with sha256 checksums:
	ntfsclone -s /dev/hdX -o - | nice -19 xz -v9ekC sha256 -T 2 > /path/to/ComputerName_OSname.ntfsclone.xz
To restore a partition with xz compression:
	xz -dc /path/to/ComputerName_OSname.ntfsclone.xz | ntfsclone -rO /dev/hdX -

==leaving other partitions unaffected, when restoring boot sector from previous backup==
restore the boot sector with out destroying the "partition info", restoring just the Windows "partition info"
refer to mbr info to do this

just make certain not to change the 463rd to 512th bytes in the boot sector

EXAMPLE(work in progress):
save current partition info
dd bs=1M count=1 if=/dev/hdX of=/path/to/external_drive/ComputerName_DriveName.boot
then

reinstall windows 
dd if=/media/sda2/WINXPSR1930NXbackup10-8-2010.boot bs=462 count=1 of=/dev/sda

===MBR INFO===
MBR SECTOR NAME				BYTES
code area					440(max. 446)
disk signature (optional)	4
Usually nulls; 0x0000		2
Table of primary partitions	64(Four 16-byte entries, IBM partition table scheme)
MBR signature;0xAA55		2

MBR, total size: 446 + 64 + 2 =	512

===Vista or WIN7 extra 100mb partition problem===
Use the following from UkonCornelias to prevent WIN7 or Vista from creating a useless 100MB boot partition
@http://social.technet.microsoft.com/Forums/en/w7itproinstall/thread/51442b60-c2dc-457d-92a7-a49cbbcbbf2f:

During Setup, if you create a new partition on a clean HDD (no partitions), or delete all partitions and then create a new one - from the Partition screen in Setup, Win7 will create the 100MB boot partition, and you can't stop it/cancel it. If you want to install Win7 to a clean HDD, but don't want the boot partition do this:

At the first setup screen (Language, Keyboard, etc.) press SHIFT+F10. This will open a command prompt window. Enter the following diskpart commands to create a partition.

- Diskpart
- List disk
(this command is important. It will show you what disk drives you have. Most likely your hard drive will be will be Disk 0, but you need to check it first.)

- select disk 0
- clean
- create partition primary size=12800
(this creates a partition 12800MB or 12.5GiB in size. this is the minimum size I have ever had a successful install with; If you want to use the whole hard drive, just leave off the size=number)

- select partition 1
- active
- format fs=ntfs quick label="WINDOWS"

Type Exit to leave Diskpart. Type Exit to close the command prompt. Now continue with the install. When you get to the partition screen, highlight the partition you just created and click Next. Windows will install to the partition you created and not create the 100MB boot partition. Instead, you will see a C:\Boot folder when the install is finished (like Vista has).
/*end Windows7 install*/

===Moving NTFS partitions===
Strongly advised not to be done. this how-to is thanx to Michael Dominok @ http://www.dominok.net/en/it/en.it.clonexp.html

Now, the boot-sectors of the newly cloned partition have to be modified. The partition(s) in front of the new ones have to be "skipped". This is done by inserting an offset into the partitions boot-sector. But first we've got to determine where they start. "fdisk -ul /dev/hda" shows:

   Device Boot      Start         End      Blocks   Id  System
/dev/hda1   *          63    40965749    20482843+   7  HPFS/NTFS
/dev/hda2        40965750    81979694    20506972+   7  HPFS/NTFS
/dev/hda3        81979695   122993639    20506972+   7  HPFS/NTFS
/dev/hda4       122993640   181582694    29294527+   5  Extended
/dev/hda5       122993703   181582694    29294496   83  Linux

The interesting values are listed in the "Start"-column but have to be converted into hexadecimal and rearranged in order. "printf "0x%llx\n" 40965750" printfs 40965750 in hexadecimal format "0x2711676"
"printf "%x" 40965750" would have done, too.
The hexadecimal value "2711676" has to be rearranged further. The digits have to skewed by pairs following this method:
	0xABCD EFGH => GHEF CDAB
	0x031f 9f3e => 3E9F 1F03
For "2711676" this results in "76167102"
Since we've got 4 pairs to skew but only 7 digits available we simply add a leading 0. This is as neutral in the hexadecimal system as it is in the more familiar decimal system.
Now "76167102" has to be inserted into hda2s boot-sector. That's done with "hexedit /dev/hda2"
Move the cursor to position "0x1c" and type in "76 16 71 02", then save&quit with "<STRG>-X"
Use the same procedure for hd3. 

This is simply done by running the Vista/7 startup repair.
Enter the installation DVD -> Select repair and follow the wizard.

other commands====================
sudo mkdir /mnt/susv3
sudo mount -osize=100m tmpfs /mnt/susv3 -t tmpfs
cd '/mnt/susv3' 
unlzma -ck '/home/glas/Comp Sci/C/susv3.tlz' | tar xvf -

just did this the other day 1 command then the bcdedit:
sudo xz -dc /media/DATA/Shared/Images/K53TA_WIN7.ntfsclone |sudo ntfsclone -rO /dev/sda1 -


To backup boot sector AND compress it with xz on highest compression with sha256 checksums, at the same time:
	dd bs=1M count=1 if=/dev/hdX | nice -19 xz -v9ekC sha256 > /path/to/ComputerName_DriveName.boot.xz
To backup a partition AND compress it with xz on highest compression with sha256 checksums, at the same time:
	ntfsclone -s /dev/hdX -o - | nice -19 xz -v9ekC sha256 -T 2 > /path/to/ComputerName_OSname.ntfsclone.xz
To backup a partition with no compression:
	ntfsclone -s /dev/hdX -o /path/to/ComputerName_OSname.ntfsclone
To compress it with xz when you're done:
	nice -19 xz -v9eC sha256 -T 2 /path/to/ComputerName_OSname.ntfsclone


just did this the other day 1 command then the bcdedit:
sudo xz -dc /media/owner/DATA/Shared/Images/K53TA/K53TA_WIN7SP1.ntfsclone.xz |sudo ntfsclone -rO /dev/sda1 -