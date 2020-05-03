FROM fedora:rawhide

ARG GMX_BRANCH
ARG GMX_DOUBLE
ARG PYTHON

RUN dnf -y install make cmake valgrind git gcc-c++ expat-devel fftw-devel boost-devel txt2tags ccache procps-ng gnuplot-minimal psmisc ghostscript texlive doxygen texlive-appendix texlive-wrapfig texlive-a4wide texlive-xstring vim-minimal clang llvm compiler-rt python-pip python3-lxml python3-numpy transfig texlive-units texlive-sidecap texlive-bclogo texlive-mdframed texlive-type1cm texlive-braket graphviz wget hdf5-devel lammps eigen3-devel libxc-devel ImageMagick ghostscript-tools-dvipdf python3-espresso-openmpi sudo curl clang-tools-extra python3-cma ninja-build libomp-devel clang-devel llvm-devel python3-sphinx python3-recommonmark python3-sphinx_rtd_theme

# set https://github.com/votca/buildenv/issues/22
RUN alternatives --set gnuplot /usr/bin/gnuplot-minimal

RUN wget -O /usr/bin/codecov https://raw.githubusercontent.com/junghans/codecov-bash/master/codecov
RUN chmod +x /usr/bin/codecov

# install fedora's gromacs
RUN if [ -z "${GMX_BRANCH}" ]; then \
  dnf -y install gromacs-devel gromacs gromacs-openmpi; \
fi

RUN useradd -m -G wheel votca
RUN echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER votca
ENV PATH=/usr/lib64/ccache:/usr/lib64/openmpi/bin${PATH:+:}${PATH}
ENV LD_LIBRARY_PATH=/usr/lib64/openmpi/lib${LD_LIBRARY_PATH:+:}${LD_LIBRARY_PATH}
ENV PYTHONPATH=/usr/lib64/${PYTHON:-python3.7}/site-packages/openmpi${PYTHONPATH:+:}${PYTHONPATH}
ENV CCACHE_MAXSIZE=250M
WORKDIR /home/votca
RUN mkdir .ccache

# create latex.fmt before manual build
# parallel build might trigger a raise condition for non-exisiting latex.fmt when multiple latex get executed
RUN mkdir latex && cd latex && \
printf '\\documentclass{article}\n\\begin{document}\ntest\n\\end{document}' > test.tex && \
latex test.tex && cd .. && rm -rf latex

RUN pip install --user coverxygen
# build certain gromacs version as user
RUN if [ -n "${GMX_BRANCH}" ] && [ "${GMX_BRANCH}" != "none" ]; then \
  git clone --depth 1 -b "${GMX_BRANCH}" https://github.com/gromacs/gromacs.git && \
  mkdir gromacs/build && cd gromacs/build && \
  if [ "${GMX_BRANCH}" = master ] || [ "${GMX_BRANCH}" = release-2020 ]; then \
    gmx_cmake_opts="-DGMX_INSTALL_LEGACY_API=ON"; \
  fi && \
  cmake -DCMAKE_INSTALL_PREFIX=/usr -DGMX_SIMD=SSE2 -DGMX_DOUBLE=${GMX_DOUBLE} ${gmx_cmake_opts} .. && \
  make -j3; \
  sudo make install; \
  cd ../..; \
fi
