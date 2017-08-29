//
//  ViewController.m
//  录音
//
//  Created by 盼 on 2017/8/14.
//  Copyright © 2017年 pan. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

@interface ViewController ()
/** 录音对象 */
@property (nonatomic,strong) AVAudioRecorder * recoder;
/** 音频文件地址 */
@property (nonatomic,strong) NSURL * url;
/** 音频播放器 */
@property (nonatomic,strong) AVAudioPlayer * player;
/** 录音文件路径 */
@property (nonatomic,strong) NSString * recordeFilePath;

/**
 转换的Mp3文件地址
 */
@property (nonatomic,strong) NSURL * mp3Url;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"%@",NSHomeDirectory());
}
- (IBAction)startRecord:(UIButton *)sender {
    
    [self.recoder record];
}

- (IBAction)stopRecord:(id)sender {
    [self.recoder stop];
    
    [self convertToMp3];
}


- (IBAction)playSound:(id)sender {

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    NSError * error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:self.url error:&error];
    [self.player play];
}


- (void)convertToMp3
{
    NSString *fileName = [NSString stringWithFormat:@"/%@.mp3", @"test"];
    NSString *filePath = [[NSHomeDirectory() stringByAppendingFormat:@"/Documents/"] stringByAppendingPathComponent:fileName];
    NSLog(@"%@",filePath);
    _mp3Url = [NSURL URLWithString:filePath];
    
    @try {
        int read,write;
        //只读方式打开被转换音频文件
        FILE *pcm = fopen([self.recordeFilePath cStringUsingEncoding:1], "rb");
        fseek(pcm, 4 * 1024, SEEK_CUR);//删除头，否则在前一秒钟会有杂音
        //只写方式打开生成的MP3文件
        FILE *mp3 = fopen([filePath cStringUsingEncoding:1], "wb");
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE * 2]; 
        unsigned char mp3_buffer[MP3_SIZE];
        //这里要注意，lame的配置要跟AVAudioRecorder的配置一致，否则会造成转换不成功
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);//采样率
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            
            //以二进制形式读取文件中的数据
            read = (int)fread(pcm_buffer, 2 * sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            //二进制形式写数据到文件中  mp3_buffer：数据输出到文件的缓冲区首地址  write：一个数据块的字节数  1:指定一次输出数据块的个数   mp3:文件指针
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);

    } @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    } @finally {
        NSLog(@"MP3生成成功!!!");
    }
}


- (AVAudioRecorder *)recoder
{
    if (!_recoder) {
        
        //存放录音文件的地址
        NSString * path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString * filePath = [path stringByAppendingPathComponent:@"123.caf"];
        self.recordeFilePath = filePath;
        NSURL * url = [NSURL URLWithString:filePath];
        self.url = url;
        
        //录音设置
        NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
        //设置录音格式
        [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
        //采样率 采样率必须要设为11025才能使转化成mp3格式后不会失真
        [recordSettings setValue :[NSNumber numberWithFloat:11025.0] forKey: AVSampleRateKey];//44100.0
        //通道数要转换成MP3格式必须为双通道
        [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];

        //音频质量,采样质量
        [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
        
        //创建录音对象
        _recoder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSettings error:nil];
        
        [_recoder prepareToRecord];
    }
    
    return _recoder;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
