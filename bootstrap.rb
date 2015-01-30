r,w = IO.pipe
system("bundle", "check", :out => w, :err => w) or
  system("bundle", "install", "--path", ".bundle")
