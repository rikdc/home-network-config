import yaml

with open("meta/argument_specs.yml", "r") as f:
    data = yaml.load(f, Loader=yaml.FullLoader)

with open("README.md", "w") as f:
    f.write("# Role Arguments\n\n")
    for arg in data["args"]:
        f.write(f"## {arg['name']}\n\n")
        f.write(f"**Default**: {arg.get('default', 'N/A')}\n\n")
        f.write(f"{arg.get('description', '')}\n\n")
