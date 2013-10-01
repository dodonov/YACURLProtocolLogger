//
//  NSURLRequest+Mustache.m
//
//  Copyright (c) 2013 Alexey Dodonov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSURLRequest+Mustache.h"
#import "NSDictionary+Mustache.h"

@implementation NSURLRequest (Mustache)

- (NSString *)m_title
{
    return @"Request";
}

- (NSArray *)m_HTTPHeaders
{
    return [[self allHTTPHeaderFields] m_printableArray];
}

- (NSArray *)m_otherProperties
{
    NSDictionary *props = @{@"Main Document URL": [self m_mainDocumentURL],
                            @"Timeout Interval" : [self m_timeoutInterval]};

    return [props m_printableArray];
}

- (NSString *)m_mainDocumentURL
{
    return self.mainDocumentURL? [self.mainDocumentURL absoluteString] : @"";
}

- (NSString *)m_timeoutInterval
{
    NSString *result = @"None";
    NSTimeInterval t = [self timeoutInterval];
    if (t > 60*60*12) {
        result = @"Unlimited";
    }
    else {
        result = [NSString stringWithFormat:@"%.3f", t];
    }
    return result;
}

- (BOOL)m_hasBody
{
    return [[self HTTPBody] length] > 0;
}

- (NSString *)m_bodySize
{
    NSString *result = @"None";
    if ([self HTTPBodyStream] != nil) {
        result = @"Stream";
        // TODO: make stream body visible in HTTP interface.
    }
    else if ([[self HTTPBody] length] > 0) {
        result = [NSString stringWithFormat:@"%d bytes", [[self HTTPBody] length]];
    }
    return result;
}

- (BOOL)m_isRequest
{
    return YES;
}

@end
