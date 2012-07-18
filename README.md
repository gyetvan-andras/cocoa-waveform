# Cocoa Waveform Audio Player Control #

A cocoa audio player component which displays the waveform of the audio file.

## How to use it ? ##

### OSX
Add a view in IB and set the class to WaveFormViewOSX
### iOS
Add a view in IB and set the class to WaveFormViewIOS

Then you can use:
<ul>
<li>(void) openAudioURL:(NSURL *)url;</li>
</ul>

Note on iOS: on iOS you should provide a direct URL to the audio data, you cannot use URL obtained from MPMediaItemPropertyAssetURL. You should extract the content from AVAsset. More on this you can read http://www.subfurther.com/blog/2010/12/13/from-ipod-library-to-pcm-samples-in-far-fewer-steps-than-were-previously-necessary/
In the sample application you should add an mp3 file, named sample.mp3 to the iOS app, because I removed it to avoid legal concerns.

## How to hack it ? ##

If you would like to change visual appearance you should take a look at WaveFormView???:drawRect and hack as you wish.

 