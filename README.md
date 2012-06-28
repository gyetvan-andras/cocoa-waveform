# Cocoa Waveform Audio Player Control #

A cocoa audio player component which displays the waveform of the audio file.

## How to use it ? ##

Just add a view in IB and set the class to WaveFormView then you can use:
1. - (void) openAudio:(NSString *)path;
2. - (void) openAudioURL:(NSURL *)url;

## How to had it ? ##

If you would like to change visual appereance you should take a look at WaveFormView:drawRect and hack as you wish.

 