"""
This script aid the creation of the moved {} lines in terrafrom while refactoring.

You shall run it either pasting the output of

terraform plan | grep "created\|destroyed"

into the SAMPLE_LINES, or directly by doing

terraform plan | grep "created\|destroyed" | python3 scripts/format_moved.py
"""

SAMPLE_LINES = """
  # aws_alb.oonidataapi will be destroyed
  # aws_alb_listener.front_end will be destroyed
  # aws_alb_listener.front_end_https will be destroyed
  # aws_alb_target_group.oonidataapi will be destroyed
  # aws_autoscaling_group.app will be destroyed
  # aws_cloudwatch_log_group.app will be destroyed
  # aws_ecs_service.oonidataapi will be destroyed
  # aws_ecs_task_definition.oonidataapi will be destroyed
  # aws_iam_instance_profile.app will be destroyed
  # aws_iam_role.app_instance will be destroyed
  # aws_iam_role.ecs_service will be destroyed
  # aws_iam_role.ecs_task will be destroyed
  # aws_iam_role_policy.ecs_service will be destroyed
  # aws_iam_role_policy.ecs_task will be destroyed
  # aws_iam_role_policy.instance will be destroyed
  # aws_launch_template.app will be destroyed
  # aws_security_group.instance_sg will be destroyed
  # aws_security_group.lb_sg will be destroyed
  # aws_security_group.ooniapi will be created
  # module.ooni_dataapi.aws_alb.oonidataapi will be created
  # module.ooni_dataapi.aws_alb_listener.front_end will be created
  # module.ooni_dataapi.aws_alb_listener.front_end_https will be created
  # module.ooni_dataapi.aws_alb_target_group.oonidataapi will be created
  # module.ooni_dataapi.aws_autoscaling_group.app will be created
  # module.ooni_dataapi.aws_cloudwatch_log_group.app will be created
  # module.ooni_dataapi.aws_ecs_service.oonidataapi will be created
  # module.ooni_dataapi.aws_ecs_task_definition.oonidataapi will be created
  # module.ooni_dataapi.aws_iam_instance_profile.app will be created
  # module.ooni_dataapi.aws_iam_role.app_instance will be created
  # module.ooni_dataapi.aws_iam_role.ecs_service will be created
  # module.ooni_dataapi.aws_iam_role.ecs_task will be created
  # module.ooni_dataapi.aws_iam_role_policy.ecs_service will be created
  # module.ooni_dataapi.aws_iam_role_policy.ecs_task will be created
  # module.ooni_dataapi.aws_iam_role_policy.instance will be created
  # module.ooni_dataapi.aws_launch_template.app will be created
  # module.ooni_dataapi.aws_security_group.instance will be created
  # module.ooni_dataapi.aws_security_group.web will be created
"""

import sys


def find_most_similar(destroy_lines, create_line):
    no_mod_name = ".".join(create_line.split(".")[2:])
    for l in destroy_lines:
        if no_mod_name == l:
            return l

    just_resource = no_mod_name.split(".")[0]
    for l in destroy_lines:
        if l.startswith(just_resource):
            return l
    return None

def format_moved(name_from, name_to):
    return f"""
moved {{
    from = {name_from}
    to = {name_to}
}}
"""

def get_create_destroy_lines():
    destroy_lines = []
    create_lines = []

    #for line in SAMPLE_LINES.split("\n"):
    for line in sys.stdin:
        line = line.strip()
        if line == "":
            continue
        if line.endswith("will be destroyed"):
            destroy_lines.append(line.split(" ")[1])
        if line.endswith("will be created"):
            create_lines.append(line.split(" ")[1])
    return create_lines, destroy_lines

def main():
    create_lines, destroy_lines = get_create_destroy_lines()

    for create_rsrc in create_lines:
        most_similar = find_most_similar(destroy_lines, create_rsrc)
        if most_similar:
            destroy_lines.remove(most_similar)

        print(format_moved(most_similar, create_rsrc))

    for l in destroy_lines:
        print(format_moved(l, None))

if __name__ == "__main__":
    main()
