#import "espeak-ng/bundle.h"
#import "espeak-ng/espeak_ng.h"

const NSErrorDomain EspeakErrorDomain = @"EspeakErrorDomain";

@implementation EspeakLib
+ (BOOL)ensureBundleInstalledInRoot:(NSURL*_Nonnull)root error:(NSError*_Nullable*_Nonnull)error {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSURL *dataRoot = [root URLByAppendingPathComponent:@"espeak-ng-data"];

  FILE *nullout = nil;

  if (![fm fileExistsAtPath:dataRoot.path]) {
    nullout = fopen("/dev/null", "w");

    NSBundle *bundle = [NSBundle bundleWithPath:@"espeak-ng_libespeak-ng.bundle"];
    if (!bundle) bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"espeak-ng_libespeak-ng" withExtension:@"bundle"]];
    NSURL *bdl = [bundle resourceURL];
    if (![fm copyItemAtURL:[bdl URLByAppendingPathComponent:@"espeak-ng-data"] toURL:dataRoot error:error]) return NO;
    espeak_ng_InitializePath([root.path cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString *ph_root = [bdl URLByAppendingPathComponent:@"phsource" isDirectory:YES].path;
    NSString *dict_root = [bdl URLByAppendingPathComponent:@"dictsource" isDirectory:YES].path;

    espeak_ng_STATUS res;
    char errorbuf[256];
    if ((res = espeak_ng_CompileIntonationPath([ph_root cStringUsingEncoding:NSUTF8StringEncoding], nil, nullout, nil)) != ENS_OK) {
      espeak_ng_GetStatusCodeMessage(res, errorbuf, sizeof(errorbuf));
      *error = [NSError errorWithDomain:EspeakErrorDomain code:res userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:errorbuf] }];
      goto fail;
    }
    if ((res = espeak_ng_CompilePhonemeDataPath(22050, [ph_root cStringUsingEncoding:NSUTF8StringEncoding], nil, nullout, nil)) != ENS_OK) {
      espeak_ng_GetStatusCodeMessage(res, errorbuf, sizeof(errorbuf));
      *error = [NSError errorWithDomain:EspeakErrorDomain code:res userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:errorbuf] }];
      goto fail;
    }

    NSArray<NSURL*>* dict_files = [fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:dict_root] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants error:error];
    if (!dict_files) return NO;
    NSMutableSet<NSString*>* dict_names = [NSMutableSet new];
    espeak_VOICE v;
    for (NSURL *u in dict_files) {
      NSArray<NSString*>* comps = [[u lastPathComponent] componentsSeparatedByString:@"_"];
      if (comps.count != 2) continue;
      if (![comps.lastObject isEqualToString:@"rules"]) continue;
      NSString *d = comps.firstObject;

      bzero(&v, sizeof(v));
      v.languages = [d cStringUsingEncoding:NSUTF8StringEncoding];
      if ((res = espeak_ng_SetVoiceByProperties(&v)) != ENS_OK) {
        espeak_ng_GetStatusCodeMessage(res, errorbuf, sizeof(errorbuf));
        *error = [NSError errorWithDomain:EspeakErrorDomain code:res userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:errorbuf] }];
        goto fail;
      }
      if ((res = espeak_ng_CompileDictionary([[dict_root stringByAppendingString:@"/"] cStringUsingEncoding:NSUTF8StringEncoding], [d cStringUsingEncoding:NSUTF8StringEncoding], nullout, 0, nil)) != ENS_OK) {
        espeak_ng_GetStatusCodeMessage(res, errorbuf, sizeof(errorbuf));
        *error = [NSError errorWithDomain:EspeakErrorDomain code:res userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithUTF8String:errorbuf] }];
        goto fail;
      }
    }
    fclose(nullout);
  }
  return YES;
fail:
  fclose(nullout);
  [fm removeItemAtURL:dataRoot error:nil];
  return NO;
}
@end
