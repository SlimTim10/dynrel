#!/usr/bin/perl
#
# Written by SlimTim10
# 2012-11-25

use warnings;
use strict;

sub usage {
    print "usage: $0 elf_file\n";
    exit();
}

usage() unless @ARGV == 1;

my $prog = shift;
my @main = `objdump -d -j .text -M intel $prog | perl -ne 'print if /<main>:/ .. /^\x0a/'` or usage();
my @plt = `objdump -d -j .plt -M intel $prog | perl -ne 'print if /<.plt>:/ .. /^\x0a/'` or usage();
my @reloc = `objdump -R $prog` or usage();
my $addr;
my $raddr;

open(my $fout, ">", "$prog.main") or die("Can't open $prog.main: $!\n");

while (my $mline = shift @main) {
    if ($mline =~ m/call\s+?([0-9a-f]+)/) {
        $addr = $1;
        for my $i (0 .. $#plt) {
            if ($plt[$i] =~ m/\s*$addr:.+jmp.+(0x[0-9a-f]+)/) {
                $raddr = $1;
                $plt[$i+1] =~ m/\s*([0-9a-f]+):/;
                $raddr = hex($raddr) + hex($1);
                last;
            }
        }
        next if (!$raddr);
        $raddr = sprintf("%x", $raddr);
        for my $i (0 .. $#reloc) {
            if ($reloc[$i] =~ m/[0-9a-f]*$raddr\s+?\w+?\s+(\w+)/) {
                my $tmp = $1;
                $mline =~ s/<.*>/<$tmp>/;
                last;
            }
        }
    }
    print $fout $mline;
}
