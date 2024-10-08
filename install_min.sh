#!/bin/bash
# this is the Ollama-Companion bash installer for Linux 
# This installer is meant to be ran from a direct download or from the ollama-companion repo



# These packages are needed to install or use ollama/companion.
COMMON_PACKAGES="aria2 make gcc git pciutils curl" 
VERSION="4"
LOGFILE="logs/installation.log"

# Function to install packages per distrobution type.
install_packages() {
    if [[ "$1" == "Ubuntu" || "$1" == "Debian" ]]; then
        sudo apt update
        sudo apt install -y $COMMON_PACKAGES
        sudo apt-get install -y ca-certificates curl gnupg
        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
        echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
        # Instal nodejs V18
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
        NODE_MAJOR=18
        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
        sudo apt-get update && sudo apt-get install cloudflared && sudo apt-get install nodejs -y
        sudo npm install --global yarn
        sudo npm install --global npx
    elif [[ "$1" == "Arch" ]]; then
        sudo pacman -Syu
        sudo pacman -S $COMMON_PACKAGES
        sudo pacman -Syu cloudflared
    elif [[ "$1" == "RedHat" ]]; then
        sudo yum update
        sudo yum install -y $COMMON_PACKAGES
        curl -fsSL https://pkg.cloudflare.com/cloudflared-ascii.repo | sudo tee /etc/yum.repos.d/cloudflared.repo
        sudo yum update && sudo yum install cloudflared
    fi
}

check_requirment_anythingllm(){
    npm --version 
    yarn --version
}

# Function to check Python 3.10 and python3.10-venv
check_python() {
    PYTHON_VERSION=$(python3 --version 2>/dev/null | grep -oP '(?<=Python )\d+\.\d+')
    PYTHON_VENV_PACKAGE="python3.10-venv" 

    if [[ $PYTHON_VERSION < 3.10 ]]; then
        echo "Python 3.10 or higher is not installed. Please install it using your distribution's package manager."
        case $1 in
            "Ubuntu"|"Debian")
                echo "Run: sudo apt install python3.10 python3.10-venv (or higher)" 
                ;;
            "Arch")
                echo "Run: sudo pacman -S python3.10 python3.10-venv (or higher)"  Adjust if package names differ
                ;;
            "RedHat")
                echo "Run: sudo yum install python3.10 python3.10-venv (or higher)" # Adjust if package names differ
                ;;
            *)
                echo "Unsupported distribution."
                ;;
        esac
    else
        echo "Python 3.10 or higher is installed."
    fi
}

# Function to create a Python virtual environment
create_python_venv() {
    if command -v python3.10 >/dev/null 2>&1; then
        python3.10 -m venv companion_venv
        echo "Virtual environment created with Python 3.10 in 'companion_venv' directory."
    elif command -v python3.11 >/dev/null 2>&1; then
        python3.11 -m venv companion_venv
        echo "Virtual environment created with Python 3.11 in 'companion_venv' directory."
    elif command -v python3 >/dev/null 2>&1; then
        python3 -m venv companion_venv
        echo "Virtual environment created with default Python 3 in 'companion_venv' directory."
    else
        echo "No suitable Python 3 version found. Please install Python 3."
        return 1
    fi
}


# Function to activate the virtual environment
activate_venv() {
    source companion_venv/bin/activate
    echo "Virtual environment activated."
}

# Function to install dependencies from requirements.txt
pip_dependencies() {
    pip install -r requirements.txt
    echo "Dependencies installed from requirements.txt."
}


# Detect the OS
OS="Unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
fi

# Function to read the installation type from the log file
read_installation_type() {
    if [ -f "$LOGFILE" ]; then
        local installed_type=$(sed -n '2p' "$LOGFILE")
        echo $installed_type
    else
        echo "none"
    fi
}

# Function to determine if an upgrade is needed
is_upgrade_needed() {
    local current_installation=$(read_installation_type)
    local new_installation=$1

    case $current_installation in
        minimal)
            [[ "$new_installation" == "standard" || "$new_installation" == "large" ]]
            ;;
        standard)
            [[ "$new_installation" == "large" ]]
            ;;
        interactive)
            return 0 # Always rerun interactive
            ;;
        *)
            return 1 # No upgrade needed or unrecognized type
            ;;
    esac
}
# Function to clone ollama-companion repository
clone_ollama_companion() {
    current_dir=$(basename "$PWD")
    if [ "$current_dir" != "Ollama-Companion" ]; then
        git clone https://github.com/TommySinPolyU/Ollama-Companion.git
        cd Ollama-Companion
        echo "Cloned ollama-companion and changed directory to ollama-companion"
    else
        echo "Already inside ollama-companion directory, skipping clone."
    fi
}

# Function to clone llama.cpp repository and run make in its directory
clone_and_make_llama_cpp() {
    git clone https://github.com/ggerganov/llama.cpp.git
    make -C llama.cpp
    echo "Cloned llama.cpp and ran make in the llama.cpp directory"
}

# Interactive options
# Function to install Ollama
install_ollama() {
    read -p "Do you want to install Ollama on this computer? (y/n) " answer
    case $answer in
        [Yy]* )
            curl https://raw.githubusercontent.com/TommySinPolyU/ollama_backend_panel/main/ollama_install.sh | sh
            echo "Ollama installed on this host."
            ;;
        * )
            echo "Ollama installation skipped."
            ;;
    esac
}
# Function to instal Ollama headless
install_ollama_headless(){
    curl https://raw.githubusercontent.com/TommySinPolyU/ollama_backend_panel/main/ollama_install.sh | sh
    echo "Ollama Installed"
}

# Run Ollama at backend
run_ollama_backend(){
    echo "Starting Ollama Backend"
    OLLAMA_ORIGINS=* OLLAMA_HOST=0.0.0.0 ollama serve &
}

download_required_models(){
    #ollama pull shaw/dmeta-embedding-zh
    #ollama pull rjmalagon/gte-qwen2-7b-instruct-embed-f16
    ollama pull quentinz/bge-large-zh-v1.5
    #ollama pull pokmon/llama3-8b-chinese
    ollama pull qwen2
    #ollama pull llama3.1:8b
    #ollama pull wangshenzhi/llama3-8b-chinese-chat-ollama-q8
}


clean_build_llama_cpp() {
    echo "Do you want to clean build llama.cpp? (yes/no)"
    read clean_build_response
    if [[ $clean_build_response == "yes" ]]; then
	git clone http://github.com/ggerganov/llama.cpp.git
        make -C llama.cpp
        echo "Clean build of llama.cpp completed."
    else
        echo "Skipping clean build of llama.cpp."
    fi
}
# Function to help you install python3.10 interactively
interactive_check_python() {
    PYTHON_VERSION=$(python3 --version 2>/dev/null | grep -oP '(?<=Python )\d+\.\d+')
    if [[ $PYTHON_VERSION < 3.10 ]]; then
        echo "Python 3.10 or 3.11 is required. Would you like to install it? (yes/no)"
        read install_python
        if [[ $install_python == "yes" ]]; then
            case $OS in
                "Ubuntu"|"Debian")
                    sudo apt install -y python3.10 python3.10-venv || sudo apt install -y python3.11 python3.11-venv
                    ;;
                "Arch")
                    sudo pacman -S python3.10 python3.10-venv || sudo pacman -S python3.11 python3.11-venv
                    ;;
                "RedHat")
                    sudo yum install -y python3.10 python3.10-venv || sudo yum install -y python3.11 python3.11-venv
                    ;;
                *)
                    echo "Unsupported distribution for automatic Python installation."
                    ;;
            esac
        fi
    else
        echo "Python 3.10 or higher is already installed."
    fi
}

# Functions for install the Anything LLM
clone_anythingllm(){
    git clone https://github.com/TommySinPolyU/anything-llm.git
    cd anything-llm
    yarn setup
}
copy_envfiles(){
     cp server/.env.example server/.env
     cp frontend/.env.example frontend/.env
}
migrate_database(){
    cd server && npx prisma generate --schema=./prisma/schema.prisma
    cd ../
    cd server && npx prisma migrate deploy --schema=./prisma/schema.prisma
}

# function for running the Anything LLM frontend, server and collection
start_anythingllm(){
    # Build and Run the frontend UI
    cd ../
    cd frontend && yarn build
    cd ../
    cp -R frontend/dist server/public
    # Run Server and Collector in the background
    cd server && NODE_ENV=production node index.js &
    cd collector && NODE_ENV=production node index.js &
}
    


write_to_log() {
    local installation_type=$1
    echo "Writing to log file..."
    echo "$VERSION" > "$LOGFILE"
    echo "$installation_type" >> "$LOGFILE"
}

run_start_script(){
    chmod +x start.sh
    ./start.sh
}


# END message when the installation is completed

END_MESSAGE="Successfully installed"


## Installation types
# Minimal installation function
install_minimal() {
    echo "Starting minimal installation..."
    install_packages "$OS"
    check_python "$OS"
    clone_ollama_companion
    create_python_venv
    activate_venv
    pip_dependencies
    write_to_log "minimal"
    echo "$END_MESSAGE" 
}

# Medium installation function
install_medium() {
    echo "Starting standard installation..."
    install_packages "$OS"
    check_python "$OS"
    clone_ollama_companion
    clone_and_make_llama_cpp
    create_python_venv
    activate_venv
    pip_dependencies
    write_to_log "standard"
    echo "$END_MESSAGE" 
}

# Large installation function
install_large() {
    echo "Starting complete installation..."
    install_packages "$OS"
    check_python "$OS"
    clone_ollama_companion
    clone_and_make_llama_cpp
    create_python_venv
    activate_venv
    pip_dependencies
    pip install torch 
    install_ollama
    write_to_log "large"
    echo "$END_MESSAGE"
}

install_colab() {
    echo "Starting Colab installation..."
    # Redirect stdout and stderr to /dev/null for all commands
    echo "Installing required packages..."
    install_packages "$OS" > /dev/null 2>&1
    echo "Checking Node and Yarn Version"
    check_requirment_anythingllm > /dev/null 2>&1
    #echo "Cloning the Ollama Companion repository..."
    #clone_ollama_companion > /dev/null 2>&1
    echo "Cloning and Initializing the Anything-LLM repository..."
    clone_anythingllm > /dev/null 2>&1
    echo "Cloned the Anything-LLM repository..."
    echo "Copying environment files..."
    copy_envfiles > /dev/null 2>&1
    echo "Copied environment files..."
    echo "Migrating and preparing database file"
    migrate_database > /dev/null 2>&1
    echo "Migrated the Anything-LLM repository..."
    echo "Starting Anything-LLM..."
    start_anythingllm
    echo "Anything-LLM is running on http://localhost:3001"
    echo "Installing Python dependencies..."
    pip_dependencies > /dev/null 2>&1
    echo "Installing the HTTPX Python package..."
    pip install httpx > /dev/null 2>&1
    #echo "Downloading pre-compiled llama.cpp binaries..."
    #wget https://huggingface.co/luxadev/llama.cpp_binaries/resolve/main/llama.cpp_latest.tar.gz -O /tmp/llama.cpp_latest.tar.gz > /dev/null 2>&1
    #echo "Extracting the downloaded binaries..."
    #tar -xzvf /tmp/llama.cpp_latest.tar.gz -C /content/Ollama-Companion/ > /dev/null 2>&1
    echo "Installing Ollama in headless mode..."
    install_ollama_headless
    echo "Stating Ollama"
    run_ollama_backend > /dev/null 2>&1
    sleep 5
    echo "Downloading required models"
    download_required_models
    echo "Logging installation type..."
    #write_to_log "colab"
    echo "$END_MESSAGE"
}


# Colab compile installation function
install_colab_compile() {
    echo "Starting Colab compile installation..."
    rm -r /content/Ollama-Companion/llama.cpp
    install_packages "$OS"
    check_python "$OS"
    clone_ollama_companion
    pip install httpx
    clone_and_make_llama_cpp
    pip_dependencies
    install_ollama_headless
    write_to_log "colab_compile"
    echo "$END_MESSAGE"
}

# Interactive installation function
install_interactive() {
    echo "Starting interactive installation..."
    install_ollama
    interactive_check_python
    echo "Cloning Ollama-companion directory"
    clone_ollama_companion
    echo "Do you want to use the included virtual environment and install all Python dependencies? (recommended) (yes/no)"
    read use_venv_response
    if [[ $use_venv_response == "yes" ]]; then
        create_python_venv
        activate_venv
        pip_dependencies
        pip install torch
        write_to_log "interactive"
        echo "Virtual environment set up and dependencies installed."
    else
        echo "Skipping virtual environment setup and Python dependency installation."
        echo "Install the needed python dependencies from the requirements.txt with pip install -r requirements.txt"
        echo "Recommended to install these python libraries in a virtual environment."
    fi
   
    # Ask the user if they want to start Ollama Companion directly
    read -p "Do you want to start Ollama Companion directly? (yes/no) " start_now_response
    if [[ $start_now_response == "yes" ]]; then
        run_start_script
    else
        echo "You can run start.sh from the ollama-companion directory to get started."
    fi
    echo "$END_MESSAGE"
}

main() {
    # Detect the OS
    OS="Unknown"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    fi

    local install_ollama_flag=0
    local block_start_script_flag=0
    local requested_installation="standard" # Set default installation to standard

    # Parse all arguments
    for arg in "$@"; do
        case $arg in
            -minimal|-min)
                requested_installation="minimal"
                ;;
            -large|-l)
                requested_installation="large"
                ;;
            -interactive|-i)
                requested_installation="interactive"
                ;;
            -colab)
                requested_installation="colab"
                ;;
            -colab_compile)
                requested_installation="colab_compile"
                ;;
            -ollama)
                install_ollama_flag=1
                ;;
            -b|-block)
                block_start_script_flag=1
                ;;
        esac
    done

    # Check if an upgrade is needed and perform installation
    if is_upgrade_needed $requested_installation; then
        echo "Upgrade needed. Installing $requested_installation version."
    else
        echo "Proceeding with $requested_installation installation."
    fi

    case $requested_installation in
        minimal)
            install_minimal
            ;;
        standard)
            install_medium
            ;;
        large)
            install_large
            ;;
        interactive)
            install_interactive
            ;;
        colab)
            install_colab
            ;;
        colab_compile)
            install_colab_compile
            ;;
    esac

    # Install Ollama if the flag is set
    if [[ $install_ollama_flag -eq 1 ]]; then
        echo "Installing Ollama..."
        install_ollama_headless
        
        #echo "Stating Ollama"
        #run_ollama_backend
        #echo "Downloading required models"
        #download_required_models
        
    fi

    # Run start script if the block flag is not set
    #if [[ $block_start_script_flag -eq 0 ]]; then
    #    run_start_script
    #fi
}

# Call the main function with all passed arguments
main "$@"

