library = Library.new do
  source :mpd # :itunes, :folder
  output :mpd # :m3u, :xspf

  filter_by length: 45..600 # Select only songs between 45 and 600 seconds long
  # Might include syntactic sugar for "45.seconds..10.minutes" later
  filter_by bitrate: 128..320 # Bitrate greater than 128Kbps, so not low-fi
  filter_by filetype: [:mp3] # :ogm, :aac, :flac
end

library.playlist("Punk") do
  add do
    artist "Rise Against"
    album.exclude "Revolutions Per Minute"
  end

  add do
    artists "Bad Religion", "MxPx", "NOFX", "Millencollin", "Pennywise", "Pulley"
  end

  add do
    lastfm.tags "punk", "punk rock"
  end

  add do
    lastfm.similar_to(artist: "Bad Religion")
  end

  remove rating: 1..2 # Erase songs rated 1 or 2 stars, leaving 0 and 3-5
                         # Probably only supported well by iTunes, and hard to
                         # retrieve in that particular case

  shuffle :track # :artist, :album - Reorder playlist by
  trim total_duration: 4.hours
end

library.write_playlists
# Would write out an M3U for each playlist into the playlist
# folder listed in my MPD config
