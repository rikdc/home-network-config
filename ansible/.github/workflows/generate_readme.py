import yaml

with open("meta/argument_specs.yml", "r") as f:
    data = yaml.load(f, Loader=yaml.FullLoader)

with open("README.md", "r") as f:
    readme = f.read()

start = "<!-- VARS -->"
end = "<!-- END VARS -->"

start_index = readme.find(start)
end_index = readme.find(end)

if start_index == -1 or end_index == -1:
    print("Error: could not find VARS block in README.md")
    exit(1)

new_readme = readme[:start_index + len(start)] + "\n"
for arg in data["args"]:
    new_readme += f"## {arg['name']}\n\n"
    new_readme += f"**Default**: {arg.get('default', 'N/A')}\n\n"
    new_readme += f"{arg.get('description', '')}\n\n"
new_readme += readme[end_index:]

with open("README.md", "w") as f:
    f.write(new_readme)
