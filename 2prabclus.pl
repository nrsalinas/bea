#!/usr/bin/perl
my $infile = ();
my $lat = ();
my $lon = ();
my $taxa = ();
my $minlat = 91;
my $minlon = 181;
my $maxlat = -91;
my $maxlon = -181;
my $gridSize = 0;
my @offset = 0;
$offset[0] = 0;
my $grid= {};
#$grid->[x][y][Species #] top right cell
for(my $x = 0; $x <= $#ARGV; $x++){
	if($ARGV[$x] eq '-i'){
		if(-e "$ARGV[$x+1]"){
			$infile = $ARGV[$x+1];
			}
		}
	if($ARGV[$x] eq '-g'){
		$gridSize = $ARGV[$x+1];
		}
	if($ARGV[$x] eq '-o'){
		my @bits = split(',',$ARGV[$x+1]);
		push(@offset,@bits);
		}
	}
if(length($infile) && ($gridSize > 0)){
	open(INFILE,'<',"$infile");
	my $lineCounter = 0;
	while(my $line = <INFILE>){
		chomp($line);
		my @fields = split(',',$line);
		if($lineCounter == 0){
			for(my $x = 0; $x <= $#fields; $x++){
				if($fields[$x] eq 'Latitude'){
					$lat = $x;
					}
				if($fields[$x] eq 'Longitude'){
					$lon = $x;
					}
				if($fields[$x] =~ m/Scientific name/){
					$taxa = $x;
					}				}
			}else{
				if(length($fields[$lat]) && length($fields[$lon])){
					if($minlat > $fields[$lat]){
						$minlat = $fields[$lat];
						}
					if($maxlat < $fields[$lat]){
						$maxlat = $fields[$lat];
						}
					if($minlon > $fields[$lon]){
						$minlon = $fields[$lon];
						}
					if($maxlon < $fields[$lon]){
						$maxlon = $fields[$lon];
						}
					}
				}
		$lineCounter++;
		}
	close(INFILE);
	for(my $o = 0; $o <= $#offset; $o++){
		my $path = "grid-$o";
		mkdir($path);
		my $cells = ();
		my $xCells = int(($maxlon - $minlon + $offset[$o]) / $gridSize);
		my $yCells = int(($maxlat - $minlat + $offset[$o]) / $gridSize);

		$lineCounter = 0;
		open(INFILE,'<',"$infile");
		while(my $line = <INFILE>){
			chomp($line);
			if(length($line) && ($lineCounter > 0)){
				my @fields = split(',',$line);
				my $Y = int(($fields[$lat] - $minlat + $offset[$o]) / $gridSize);
				my $X = int(($fields[$lon] - $minlon + $offset[$o]) / $gridSize);
				$cells->[$X][$Y] = 1;
				$fields[$taxa] =~ tr/"//d;
				$fields[$taxa] =~ tr/ /_/;
				$grid->{$fields[$taxa]}{$X}{$Y} = 1;
				}
			$lineCounter++;
			}
		close(INFILE);

		my $buffer = '"",';
		my $neighborhood = ();
		my @taxaKeys = keys(%$grid);
		for(my $b = 0; $b <= $xCells; $b++){
			for(my $c = 0; $c <= $yCells; $c++){
				if($cells->[$b][$c] == 1){
					#$buffer .= "\"A$b-$c\",";
					$buffer .= '"' . ((($b + 1) * $gridSize) + $minlon - $offset[$o]) . 'i' . (($b * $gridSize) + $minlon - $offset[$o]) . 'i' . ((($c + 1) * $gridSize) + $minlat - $offset[$o]) . 'i' . (($c * $gridSize) + $minlat - $offset[$o]) . '",';
					}
				}
			}
		$buffer .= "\n";
		for(my $a = 0; $a <= $#taxaKeys; $a++){
			$buffer .= "\"$taxaKeys[$a]\",";
			for(my $b = 0; $b <= $xCells; $b++){
				for(my $c = 0; $c <= $yCells; $c++){
					if($cells->[$b][$c] == 1){
						if(exists($grid->{$taxaKeys[$a]}{$b}{$c})){
							$buffer .= '1,';
							}else{
								$buffer .= '0,';
								}
						}
					}
				}
			$buffer .= "\n";
			}
		$buffer =~ s/,\n/\n/g;
		open(FILE,'>',"$path/grid.csv");
		print(FILE $buffer);
		close(FILE);
		my @areas = ();
		for(my $b = 0; $b <= $xCells; $b++){
			for(my $c = 0; $c <= $yCells; $c++){
				if($cells->[$b][$c] == 1){
					push(@areas,"$b-$c");
					my $others = ();
					for($d = ($b-1); $d <= ($b+1); $d++){
						for($e = ($c-1); $e <= ($c+1); $e++){
							if(($cells->[$d][$e] == 1) && ($d != $b) && ($e != $c) && ($d >= 0) && ($e >= 0)){
								$others .= $d . '-' . $e . ',';
								}						
							}
						}
					$neighborhood->[$#areas] = $others;
					}
				}
			}
		my $list = ();
		for(my $q = 0; $q <= $#{$neighborhood}; $q++){
			if($neighborhood->[$q]){
				my @bits = split(',',$neighborhood->[$q]);
				for(my $t = 0; $t <= $#bits; $t++){
					for(my $r = 0; $r <= $#areas; $r++){
						if($bits[$t] eq $areas[$r]){
							$list .= ($r+1) . ',';
							}
						}
					} 
				$list .= "\n";
				}else{
					$list .= "numeric(0)\n";
					}
			}

		open(FILE,'>',"$path/neighborhood.txt");
		print(FILE $list);
		close(FILE);
		
		my $external =  "./prabclus.r neighborhood.txt grid.csv $path";
		qx/$external/;
		
		
		}
	}else{   #01234567890123456789012345678901234567890123456789012345678901234567890123456789
		print("\n2prabclus.pl a Perl script to convert distribution files into Prabclus\n");
		print("compatible text files.\n\n");
		print("USAGE\n");
		print("\t2prabclus.pl -i <infile> -g # [-o #[,#...]]\n\n");
		print("where\n");
		print("-i\tspecifies a .csv infile with geographic distributions.\n");
		print("-g\tsets the size of the grid in degrees.\n");
		print("-o\tsets offset of the grid, also in degrees. Multiple values can be included\n\tby separating them with commas.\n\n");
		print("The script will output two files: \"grid.csv\" and \"neighborhood.txt\". The former\n");
		print("contains the coded distributions and the latter a vector of neighbors.\n\n");
		}

exit;
