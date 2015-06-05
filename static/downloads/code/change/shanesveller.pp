class people::shanesveller {
  include onepassword

  include homebrew
  include imagemagick
  include iterm2::stable
  include induction
  include postgresql
  include postgresapp
  include pow
  include redis
  include sublime_text_2
  include textmate::textmate2::release
  include vagrant
  include virtualbox
  include webstorm

  include alfred
  # include daisy_disk
  include dropbox
  include notational_velocity::nvalt
  include spotify

  include gitx
  include hub
  include github_for_mac

  include adium
  include chrome
  include chrome::canary
  include firefox

  package { 'tmux': }
  package { 'appledoc': }
  package { 'apple-gcc42': }
  package { 'automake': }
  package { 'autoconf': }
  package { 'libtool': }
  package { 'readline': }

  package { 'git-flow': }
  package { 'htop': }
  package { 'ssh-copy-id': }
  package { 'stow': }
  package { 'wget': }

  package { 'elixir': }
  package { 'phantomjs': }

  package { 'ctags': }

  git::config::global { 'user.email':
    value  => 'shanesveller@gmail.com'
  }

  git::config::global { 'user.name':
    value  => 'Shane Sveller'
  }

  repository { "/Users/${::boxen_user}/.oh-my-zsh":
    source => 'robbyrussell/oh-my-zsh'
  }

  repository { "/Users/${::boxen_user}/.dotfiles":
    source => 'git@github.com:shanesveller/dotfiles.git',
    extra => []
  }

  ruby::plugin { 'rbenv-gemset':
    ensure => 'v0.4.0',
    source => 'jf/rbenv-gemset'
  }

  ruby::plugin { 'rbenv-update':
    ensure => 'master',
    source => 'rkh/rbenv-update'
  }

  ruby::plugin { 'rbenv-vars':
    ensure => 'v1.2.0',
    source => 'sstephenson/rbenv-vars'
  }

  exec { "symlink dotfiles":
    command => "/bin/zsh symlink.sh",
    cwd => "/Users/${::boxen_user}/.dotfiles",
    creates => "/Users/${::boxen_user}/.localrc",
    require => [Package['stow'], Repository["/Users/${::boxen_user}/.dotfiles"]]
  }
}
