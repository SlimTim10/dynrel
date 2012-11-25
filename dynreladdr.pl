#!/usr/bin/perl
#
# Written by SlimTim10
# 2012-11-25

use warnings;
use strict;

sub usage {
    print "usage: $0 elf_file call_address\n";
    exit();
}

usage() unless @ARGV == 2;

my @plt = `objdump -d -j .plt -M intel $ARGV[0]` or usage();
my @reloc = `objdump -R $ARGV[0]` or usage();
(my $addr = lc $ARGV[1]) =~ s/0x//;
my $raddr;

while (my $line = shift @plt) {
    if ($line =~ m/\s*$addr:.+jmp.+(0x[0-9a-f]+)/) {
        $raddr = $1;
        (shift @plt) =~ m/\s*([0-9a-f]+):/;
        $raddr = hex($raddr) + hex($1);
        last;
    }
}

if (!$raddr) {print "Call to address 0x$addr not found.\n" and exit();}

$raddr = sprintf("%x", $raddr);
while (my $line = shift @reloc) {
    if ($line =~ m/[0-9a-f]*$raddr\s+?\w+?\s+(\w+)/) {
        print "$1\n";
        last;
    }
}
