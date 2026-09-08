project('pantheon-studio', 'vala', version: '0.1.0')
deps = [dependency('gtk4'), dependency('granite-7'), dependency('gio-unix-2.0'), dependency('gee-0.8')]
executable('pantheon-studio', 'src/application.vala', 'src/store.vala', dependencies: deps, install: true)
test('overrides', executable('test-overrides', 'src/test-store.vala', 'src/store.vala', dependencies: deps))
install_data('data/io.github.soltros.PantheonStudio.desktop', install_dir: get_option('datadir') / 'applications')
