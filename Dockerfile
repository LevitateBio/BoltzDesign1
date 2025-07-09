# Use CUDA base image for GPU support
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CONDA_AUTO_UPDATE_CONDA=false

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    zlib1g-dev \
    libgdbm-compat-dev \
    libnss3-dev \
    libatlas-base-dev \
    gfortran \
    libopenblas-dev \
    liblapack-dev \
    libhdf5-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libwebp-dev \
    libopenexr-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/conda \
    && rm /tmp/miniconda.sh

# Add conda to PATH
ENV PATH="/opt/conda/bin:$PATH"

# Set working directory for copying
WORKDIR /app

# Copy the entire project
COPY . /app/

# Create conda environment and install everything
RUN conda create -n boltz_design python=3.10 -y
RUN conda init bash && \
    echo "conda activate boltz_design" >> ~/.bashrc

# Set the shell to use conda environment
SHELL ["conda", "run", "-n", "boltz_design", "/bin/bash", "-c"]

# Install conda and pip dependencies
RUN conda install -c anaconda ipykernel numpy pandas pyyaml -y
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip install matplotlib seaborn prody tqdm requests pypdb py3Dmol logmd==0.1.45

# Install PyRosetta
RUN pip install pyrosettacolabsetup pyrosetta-installer
RUN python -c 'import pyrosetta_installer; pyrosetta_installer.install_pyrosetta()'

# Install boltz package FIRST
WORKDIR /app
RUN cd boltz && pip install -e . && cd ..

# Download Boltz weights and dependencies AFTER boltz is installed
RUN python -c "from boltz.main import download; from pathlib import Path; cache = Path('~/.boltz').expanduser(); cache.mkdir(parents=True, exist_ok=True); download(cache); print('✅ Boltz weights downloaded successfully!')"

# Setup LigandMPNN
RUN cd LigandMPNN && bash get_model_params.sh "./model_params" && cd ..

# Make DAlphaBall.gcc executable
RUN chmod +x "boltzdesign/DAlphaBall.gcc"

# Setup Jupyter kernel for the environment
RUN python -m ipykernel install --user --name=boltz_design --display-name="Boltz Design"

# Set default shell with conda environment activated
CMD ["conda", "run", "-n", "boltz_design", "/bin/bash"] 