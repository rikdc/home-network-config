import argparse
import os
import yaml


def generate_readme(argument_specs_file):
    # Read the argument specs from the YAML file
    with open(argument_specs_file, 'r') as f:
        argument_specs = yaml.safe_load(f)['argument_specs']

    # Change the current working directory to the parent directory of the argument_specs_file
    os.chdir(os.path.dirname(os.path.abspath(argument_specs_file)))
    os.chdir("..")

    # Check if README.md already exists in the current directory
    if os.path.exists('README.md'):
        # If README.md exists, open it and read its contents
        with open('README.md', 'r') as f:
            readme = f.read()
    else:
        # If README.md does not exist, create an empty string
        readme = ''

    # Find the start and end indices of the <!-- VARS --> and <!-- END VARS --> placeholders
    vars_start = readme.find('<!-- VARS -->')
    vars_end = readme.find('<!-- END VARS -->')

    # Create the markdown string based on the argument specs
    markdown = '\n## Role Variables\n\n'
    for task, options in argument_specs.items():
        markdown += f'\n### {task}\n\n{options["short_description"]}\n\n'
        markdown += '| Name | Description | Default |\n'
        markdown += '| --- | --- | --- |\n'
        for name, attrs in options['options'].items():
            default = attrs.get('default', '*None*')
            markdown += f'| {name} | {attrs["description"]} | {default} |\n'

    # If the <!-- VARS --> and <!-- END VARS --> placeholders exist, replace the markdown between them
    if vars_start != -1 and vars_end != -1:
        readme = readme[:vars_start +
                        len('<!-- VARS -->')] + markdown + readme[vars_end:]
    else:
        # If the <!-- VARS --> and <!-- END VARS --> placeholders do not exist, create them and insert the markdown
        readme += '\n<!-- VARS -->\n' + markdown + '<!-- END VARS -->\n'

    # Write the updated README.md file
    with open('README.md', 'w') as f:
        f.write(readme)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('argument_specs_file',
                        help='Path to the argument specs YAML file')
    args = parser.parse_args()

    # Check if argument_specs_file exists and is readable
    if not os.path.isfile(args.argument_specs_file) or not os.access(args.argument_specs_file, os.R_OK):
        print(
            f'Error: {args.argument_specs_file} does not exist or is not readable')
        exit(1)

    # Generate the README.md file
    generate_readme(args.argument_specs_file)
