//  Created by Giridhar on 09/06/17.
//  MIT Licence.
//  Modified By: [
//  Matt Thompson 9/14/18
//]

import Foundation
import ReplayKit
import AVKit



@objc class ScreenRecorder:NSObject
{
    var assetWriter:AVAssetWriter!
    var videoInput:AVAssetWriterInput!
    var audioInput:AVAssetWriterInput!
    var fileURL:URL!
    
    let viewOverlay = WindowUtil()
    
    //MARK: Screen Recording
    public func startRecording(withFileName fileName: String, recordingHandler:@escaping (Error?)-> Void)
    {
        if #available(iOS 11.0, *)
        {
            self.fileURL = URL(fileURLWithPath: ReplayFileUtil.filePath(fileName))
            assetWriter = try! AVAssetWriter(outputURL: self.fileURL, fileType:
                AVFileType.mp4)
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : UIScreen.main.bounds.size.width,
                AVVideoHeightKey : UIScreen.main.bounds.size.height
            ];
            
            var channelLayout = AudioChannelLayout.init()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_5_1_D
            let audioOutputSettings:Dictionary<String, Any> = [
                AVNumberOfChannelsKey: 6,
                AVFormatIDKey: kAudioFormatMPEG4AAC_HE,
                AVSampleRateKey: 44100,
                AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: channelLayout)),
            ];
            
            videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            
            audioInput = AVAssetWriterInput (mediaType: AVMediaType.audio, outputSettings:
                audioOutputSettings)
            audioInput.expectsMediaDataInRealTime = true
            
            assetWriter.add(videoInput);
            assetWriter.add(audioInput);
            
            //            RPScreenRecorder.shared().
            RPScreenRecorder.shared().isMicrophoneEnabled = true
            RPScreenRecorder.shared().startCapture(handler: { (sample, bufferType, error) in
                //                print(sample,bufferType,error)
                
                recordingHandler(error)
                
                if CMSampleBufferDataIsReady(sample)
                {
                    if self.assetWriter.status == AVAssetWriter.Status.unknown
                    {
                        self.assetWriter.startWriting()
                        self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                    }
                    
                    if self.assetWriter.status == AVAssetWriter.Status.failed {
                        print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
                        return
                    }
                    
                    if (bufferType == .video)
                    {
                        if self.videoInput.isReadyForMoreMediaData
                        {
                            self.videoInput.append(sample)
                        }
                    }
                    else if (bufferType == .audioMic)
                    {
                        self.audioInput.append(sample)
                    }
                }
                
            }) { (error) in
                recordingHandler(error)
                //                debugPrint(error)
            }
        } else
        {
            // Fallback on earlier versions
        }
    }
    
    public func stopRecording(handler: @escaping (Error?, Dictionary<String, Any>) -> Void)
    {
        if #available(iOS 11.0, *)
        {
            RPScreenRecorder.shared().stopCapture { (Error) in
                self.videoInput.markAsFinished();
                self.audioInput.markAsFinished();
                
                self.assetWriter.finishWriting {
                    let result: Dictionary<String, Any> = [
                        "recordings": ReplayFileUtil.fetchAllReplays(),
                        "recording": self.fileURL.absoluteString
                    ];
                    print(result)
                    handler(Error, result);
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
}


