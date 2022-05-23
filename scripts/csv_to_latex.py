import re
from string import Template
from typing import Tuple

headers = [""]


def read_file(file_name) -> list[list[str]]:
    file = open(file_name, 'r')
    lines = file.readlines()

    split_lines = []
    # Strips the newline character
    for line in lines:
        split_lines.append(line.split("\t"))
    return split_lines


def parse_lines(lines: list[list[str]], column: int, pattern: str):
    # print(headers[column])
    regexp = re.compile(pattern)
    count = 0
    dataset_name = ""
    highest_number = 0
    graph_data = ""
    for line in lines:
        if bool(regexp.search(line[0])):
            if dataset_name == "wiki_ts_200M_uint64" and len(line) == 14:
                graph_data += f'0\t'
            if len(line) != len(headers):
                continue
            if dataset_name == line[0]:
                graph_data += f'{line[column]} \t'
            else:
                dataset_name = line[0]
                graph_data += f'\n{count} {line[column]} \t'
                count += 1
            val = float((line[column]))
            if val > highest_number:
                highest_number = val
    # print(graph_data)
    # print(highest_number)
    desc = headers[column].replace('_', ' ')

    return graph_data, highest_number, desc


def make_three_plot(lines: list[list[str]], column: int):
    patterns = [r'(200M_uint64)',
                r'(200M_uint32)',
                r'([468]00M_uint64)']
    highest_num = 0
    for pattern in patterns:
        _, max_val, _ = parse_lines(lines, column, pattern)
        if max_val > highest_num:
            highest_num = max_val

    latex_plots = """
    \\begin{figure}
    \centering
    """
    for i in range(0, len(patterns)):
        graph_data, _, desc = parse_lines(lines, column, patterns[i])
        latex_plots += "\\begin{subfigure}"
        if i == 0:
            latex_plots += "{0.85\\textwidth}"
            latex_plots += make_unit64_200M_plot(graph_data, highest_num, desc)
        if i == 1:
            latex_plots += "{0.35\\textwidth}"
            latex_plots += make_unit32_plot(graph_data, highest_num, desc)
        if i == 2:
            latex_plots += "{0.6\\textwidth}"
            latex_plots += make_unit64_plot(graph_data, highest_num, desc)
        latex_plots += """
            \caption{{{caption}}}
            \label{{fig:{fig}}}
            \end{{subfigure}}
            \hfill
            """.format(caption=patterns[i].replace('_', " - ").replace("[468]00M", "400M+"), fig=desc + str(i))
    latex_plots += """
    \caption{{{caption}}}
    \label{{ fig:{fig} }}
    \end{{figure}}
    """.format(fig=headers[column].replace('_', ' '), caption=headers[column].replace('_', ' '))
    print(latex_plots)


def make_unit32_plot(data: str, max_val: int, desc: str):
    datasets = """books,
    normal,
    lognormal,
    uniform \\\\ dense,
    uniform \\\\ sparse,"""
    plots ="""
    \\addplot[draw=black,fill=blue!20, nodes near coords=ALEX] table[x index=0,y index=1] \dataset; %ALEX
    \\addplot[draw=black,fill=blue!40, nodes near coords=BTree] table[x index=0,y index=2] \dataset; %BTree
    \\addplot[draw=black,fill=blue!80, nodes near coords=PGM] table[x index=0,y index=3] \dataset; %PGM
    """
    return make_plot(data, max_val, desc, datasets, (33, 10), plots)


def make_unit64_200M_plot(data: str, max_val: int, desc: str):
    datasets = """osm\_cellids,
    wiki\_ts,
    books,
    fb,
    lognormal,
    uniform \\\\ dense,
    uniform \\\\ sparse,
    normal"""
    plots ="""
    \\addplot[draw=black,fill=blue!20, nodes near coords=ALEX] table[x index=0,y index=1] \dataset; %ALEX
    \\addplot[draw=black,fill=blue!40, nodes near coords=BTree] table[x index=0,y index=2] \dataset; %BTree
    \\addplot[draw=black,fill=blue!60, nodes near coords=ART] table[x index=0,y index=3] \dataset; %ART
    \\addplot[draw=black,fill=blue!80, nodes near coords=PGM] table[x index=0,y index=4] \dataset; %PGM
    """
    return make_plot(data, max_val, desc, datasets, (75, 20), plots)


def make_unit64_plot(data: str, max_val: int, desc: str):
    datasets = """osm\_cellids \\\\400M\_uint64,
    osm\_cellids \\\\600M\_uint64,
    osm\_cellids \\\\800M\_uint64,
    books \\\\400M\_uint64,
    books \\\\600M\_uint64,
    books \\\\800M\_uint64,"""

    plots ="""
    \\addplot[draw=black,fill=blue!20, nodes near coords=ALEX] table[x index=0,y index=1] \dataset; %ALEX
    \\addplot[draw=black,fill=blue!40, nodes near coords=BTree] table[x index=0,y index=2] \dataset; %BTree
    \\addplot[draw=black,fill=blue!60, nodes near coords=ART] table[x index=0,y index=3] \dataset; %ART
    \\addplot[draw=black,fill=blue!80, nodes near coords=PGM] table[x index=0,y index=4] \dataset; %PGM
    """
    return make_plot(data, max_val, desc, datasets, (50, 16), plots)


def make_plot(data: str, max_val: int, desc: str, datasets: str, size: Tuple[int, int], plots: str):
    templ = Template("""
    \pgfplotstableread{
    %0 - ALEX   1 - BTree   2 - ART   4 - PGM
    $data
    }\dataset
    \\resizebox{\\textwidth}{!}{
    \\begin{tikzpicture}
    \\begin{axis}[ybar,
            width=$width cm,
            height=8cm,
            ymin=0,
            ymax=$max_val,        
            ylabel={$desc},
            ymajorgrids=true,
            major x tick style=transparent,
            xtick=data,
          x axis line style={opacity=0},
            align=center,
            xticklabels = {
                $datasets
            },
            xticklabel style={yshift=-5ex},
            major x tick style = {opacity=0},
            minor x tick num = 1,
            minor tick length=2ex,
            every node near coord/.append style={
                    anchor=east,
                    rotate=90
            }
            ]
    $plots
    
    \end{axis}
    \end{tikzpicture}
    }
    """)
    return templ.substitute(max_val=max_val, desc=desc, data=data, datasets=datasets, scale=size[0], width=size[1], plots=plots)


# %0 - ALEX   1 - BTree   2 - ART   4 - PGM
# 0 32        35      20  10
# 1 28        45      23  3
# 2 30        24      25  4
# 3 10        68      70  52
# 4 10        68      70  53
# 5 10        68      70  5
# 6 10        68      70  2
# 7 10        68      70  65

def main():
    lines = read_file("../results_w0_it1.csv")
    global headers
    headers = lines[0]
    del lines[0]

    columns = [8, 11, 12]
    for column in columns:
        make_three_plot(lines, column)


if __name__ == "__main__":
    main()
