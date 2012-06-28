# Cocoa Waveform Audio Player Control #

A cocoa audio player component which displays the waveform of the audio file.

## How to use it ? ##

Just add a view in IB and set the class to WaveFormView then you can use:
<ul>
<li>(void) openAudio:(NSString *)path;</li>
<li>(void) openAudioURL:(NSURL *)url;</li>
</ul>

## How to hack it ? ##

If you would like to change visual appereance you should take a look at WaveFormView:drawRect and hack as you wish.

 