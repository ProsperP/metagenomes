def get_input_fastqs(wildcards):
    return sorted(samples_dict[wildcards.sample])


def script_path(relative_path):
    return str(Path(__file__).parent.joinpath(relative_path))


def get_name_file(wildcards):
    if wildcards.map_type == "level4ec":
        map_type = "ec"
    else:
        map_type = wildcards.map_type

    return os.path.join(config["humann"]["map_db"], f"map_{map_type}_name.txt")


def get_map_file(wildcards):
    map_type = wildcards.map_type
    return os.path.join(config["humann"]["map_db"], f"map_{map_type}_uniref90.txt")
