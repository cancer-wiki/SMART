# Record the README header demo:
#   brew install vhs
#   cd <a finished case folder's parent> && vhs assets/demo.tape
#
# Re-record whenever the pipeline's console output changes.

Output assets/demo.gif

Set FontSize 15
Set Width 1200
Set Height 640
Set Padding 18
Set Theme "Catppuccin Latte"
Set TypingSpeed 45ms

Type "bash setup_case.sh https://pubmed.ncbi.nlm.nih.gov/35773407/ data.rds demo_case"
Enter
Sleep 4s

Type "cd demo_case && bash single_case.sh"
Enter
Sleep 25s

Type "open Outputs/final_report_revised.html"
Enter
Sleep 3s
