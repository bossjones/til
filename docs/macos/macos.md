# Question: Does macos have a maximum amount of files that can be added to a folder where things like mdworker_shared start causing issues for the OS?

While macOS does not have a strict technical limit on the number of files that can be added to a folder, there are practical limitations that can cause performance issues when dealing with an extremely large number of files in a single directory. Here's what you need to know:

## File System Limitations

APFS (Apple File System), which is the default file system for macOS, has a theoretical limit of billions of files per directory[1]. However, real-world performance can be significantly impacted well before reaching this limit.

## Performance Issues

As the number of files in a folder increases, several performance issues can arise:

1. **Finder Slowdowns**: The Finder may become sluggish or unresponsive when trying to display folders with hundreds of thousands of files[3][4].

2. **Indexing Problems**: Spotlight, which uses the mdworker_shared process, can struggle with indexing extremely large directories[2].

3. **CPU and RAM Usage**: The mdworker_shared process may consume excessive CPU and RAM when dealing with folders containing a very large number of files[2].

4. **File Operations**: Basic operations like copying, moving, or deleting files can become time-consuming and resource-intensive.

## Practical Considerations

While there's no fixed number, issues typically start to become noticeable when dealing with:

- Folders containing 100,000 to 300,000 files[3]
- Directories approaching or exceeding 1 million files[5]

## Best Practices

To avoid performance issues:

1. **Use Subfolders**: Break up large collections of files into smaller subfolders, ideally containing no more than 10,000 to 25,000 files each[3].

2. **Avoid Finder for Large Directories**: Use command-line tools or specialized applications for managing folders with an extremely high number of files[3].

3. **Monitor Resource Usage**: Keep an eye on CPU and RAM usage, especially for processes like mdworker_shared[2].

4. **Regular Maintenance**: Periodically clean up and organize your files to prevent accumulation of unnecessary items.

5. **Consider File Size**: While the number of files is important, the total size of the files in a directory can also impact performance[4].

By following these practices, you can help ensure that macOS and its various processes, including mdworker_shared, continue to function efficiently even when dealing with large numbers of files.

Citations:
[1] https://www.reddit.com/r/MacOS/comments/13gmo4l/apfs_folder_file_limit_exceeded_now_locked_out/
[2] https://macsecurity.net/view/567-mdworker-shared-high-cpu-mac
[3] https://discussions.apple.com/thread/7932126
[4] https://forums.macrumors.com/threads/folder-limit.2236228/
[5] https://www.reddit.com/r/MacOS/comments/fqxzkr/catalina_using_apfs_best_practice_for_of_files_in/
[6] https://eclecticlight.co/2022/12/08/spotlight-problems-mds_stores-and-mdworker-in-trouble/
[7] https://services.dartmouth.edu/TDClient/1806/Portal/KB/ArticleDet?ID=84257

---

# Question: how do I set ulimit and file handles on macos ?

To set the ulimit and increase the maximum number of open file handles on macOS, follow these steps:

## Check Current Limits

First, check your current limits:

```bash
ulimit -n
launchctl limit maxfiles
```

The first command shows the current soft limit, while the second displays both soft and hard limits.

## Temporary Increase

To temporarily increase the limit for your current shell session:

```bash
ulimit -n 65536
```

This sets the soft limit to 65536 for the current session only[1].

## Permanent System-Wide Increase

For a permanent, system-wide change:

1. Create a file named `limit.maxfiles.plist` in `/Library/LaunchDaemons/` with the following content[1]:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>64000</string>
      <string>200000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
```

2. Change the owner of the file:

```bash
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
```

3. Load the new settings:

```bash
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
```

4. Verify the new limits:

```bash
launchctl limit maxfiles
```

## Additional Considerations

- For Java applications, you may need to pass the `-XX:-MaxFDLimit` JVM argument to remove the built-in limit of 10240[4].

- On newer macOS versions, you might encounter restrictions due to System Integrity Protection (SIP). In such cases, you may need to adjust your approach or consult Apple's documentation for the latest recommended practices[6].

- Remember that setting extremely high limits can potentially impact system stability, so choose values appropriate for your needs and system capabilities.

- After making changes, a system restart may be required for all settings to take effect fully[1].

By following these steps, you should be able to increase the ulimit and file handle limits on your macOS system. Always test thoroughly after making such changes to ensure system stability and application performance.

Citations:
[1] https://neo4j.com/developer/kb/setting-max-open-file-limits-on-osx/
[2] https://github.com/gradle/gradle/issues/17274
[3] https://docs.riak.com/riak/kv/latest/using/performance/open-files-limit/index.html
[4] https://questdb.io/blog/max-open-file-limit-macos-jvm/
[5] https://gist.github.com/tombigel/d503800a282fcadbee14b537735d202c?permalink_comment_id=3361594
[6] https://developer.apple.com/forums/thread/735798?answerId=762208022
[7] https://wilsonmar.github.io/maximum-limits/
