import sys

with open('lib/widget/dev_tools_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "      if (mounted) {\n        Navigator.pop(context); // Close panel on success\n      }",
    ""
)

with open('lib/widget/dev_tools_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Double pops removed.")
