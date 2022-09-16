//
//  TTYTerminal.m
//  ObjCCommandLine
//
//  Created by Whirlwind on 2019/8/7.
//  Copyright © 2019 dijkst. All rights reserved.
//

#import "TTYTerminal.h"
#import "TerminalBase+Private.h"
#import "ObjCShell.h"
#import "NSFileHandle+isReadableAddon.h"

#include <unistd.h>
#include <util.h>
#include <termios.h>

@implementation TTYTerminal

- (void)startProcess {
    [super startProcess];

    int amaster;

    pid_t pid = forkpty(&amaster, nil, nil, nil);
    if (pid > 0) {
        childProcessID = pid;

        outHandle = [[NSFileHandle alloc] initWithFileDescriptor:amaster closeOnDealloc:YES];
        [self watchSTDOUT:outHandle];

        inputHandle = outHandle;

        stderrEmpty = YES;

        dispatch_async(dispatch_queue_create("TTY Shell Wait Thread", DISPATCH_QUEUE_CONCURRENT), ^(void) {
            int status = 0;
            waitpid(self->childProcessID, &status, 0);
//            [self.delegate processStarted:self];
//            sleep(2);
            self.terminationStatus = WEXITSTATUS(status);
            self->taskDidTerminate = YES;
        });
    } else if (pid == 0) {
        setvbuf(stdout, nil, _IONBF, 0);
        setvbuf(stderr, nil, _IONBF, 0);
        [self runChildProcess];
    } else {
        NSLog(@"error");
    }
}

@end
