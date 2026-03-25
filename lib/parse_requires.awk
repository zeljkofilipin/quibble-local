# Parse requires.extensions and requires.skins from extension.json or skin.json.
# Uses state tracking: req=inside "requires", ext=inside "extensions", skin=inside "skins".
# Output: bare name for extensions (e.g. "CommunityConfiguration"), "skins/Name" for skins.

/"requires"/ { req=1 }                                             # entering "requires" block
req && /"extensions"/ { ext=1; next }                              # entering "extensions" sub-block
req && /"skins"/ { skin=1; next }                                  # entering "skins" sub-block
ext && /\}/ { ext=0; next }                                        # leaving "extensions" sub-block
skin && /\}/ { skin=0; next }                                      # leaving "skins" sub-block
req && /\}/ { req=0; next }                                        # leaving "requires" block
ext && /"[^"]+"/ { gsub(/^[^"]*"/, ""); gsub(/".*/, ""); print }   # extract extension name
skin && /"[^"]+"/ { gsub(/^[^"]*"/, ""); gsub(/".*/, ""); print "skins/" $0 }  # extract skin name with prefix
