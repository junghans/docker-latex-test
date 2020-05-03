FROM fedora:latest

RUN dnf -y install texlive

RUN useradd -m user
USER user
WORKDIR /home/user

RUN mkdir latex && cd latex && \
printf '\\documentclass{article}\n\\begin{document}\ntest\n\\end{document}' > test.tex && \
latex test.tex && cd .. && rm -rf latex
