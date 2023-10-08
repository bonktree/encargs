# SPDX-License-Identifier: GPL-2.0
project(
    'encargs',
    [
        'c',
    ],
    version: '1.0',
    default_options: [
        'c_std=c11',
        'warning_level=2',
    ],
)

encargs_conf = configuration_data()
encargs_conf.set_quoted('PROJECT_NAME', meson.project_name())
encargs_conf.set_quoted('PROJECT_VERSION', meson.project_version())
configure_file(output: 'encargs-config.h', configuration: encargs_conf)

add_project_arguments('-D_GNU_SOURCE', language: 'c')
# Only one executable in project.
executable(
    'encargs',
    sources: files(
        'base64.c',
        'encargs.c',
        'util.c',
    ),
    install: true,
)

subdir('tests')
