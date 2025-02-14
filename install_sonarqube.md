# Installing SonarQube on Ubuntu 24.04

This guide outlines the steps to install the latest version of SonarQube on Ubuntu 24.04.

## Prerequisites

*   **Java:** SonarQube requires a specific version of Java. Check the SonarQube documentation for the latest supported version. Install the OpenJDK:

    ```bash
    sudo apt update
    sudo apt install openjdk-17-jdk -y  # Or the required Java version
    java -version
    ```

*   **PostgreSQL:** SonarQube uses PostgreSQL as its database. Install it and create a database and user for SonarQube:

    ```bash
    sudo apt install postgresql postgresql-contrib -y
    sudo -i -u postgres
    createuser sonar
    createdb sonar -O sonar
    psql
    ALTER USER sonar WITH ENCRYPTED PASSWORD 'your_password';
    \q
    exit
    ```

## Installation

1.  **Download SonarQube:** Go to the official SonarQube download page: [https://www.sonarqube.org/downloads/](https://www.sonarqube.org/downloads/) and download the Community Edition (or your desired edition) ZIP file.  **Do not use `wget` directly; download via your browser.**

2.  **Transfer the ZIP file to your server (if needed):** If you downloaded the ZIP file on your local machine, transfer it to your Ubuntu server using `scp`, `sftp`, or a similar method. For example:

    ```bash
    scp /path/to/downloaded/sonarqube-*.zip your_username@your_server_ip:/tmp
    ```

3.  **On your server, move and extract the file:**

    ```bash
    sudo mv /tmp/sonarqube-*.zip /opt
    cd /opt
    sudo unzip sonarqube-*.zip
    ```

4.  **Rename the extracted directory (Important):** The extracted directory will have a version-specific name (e.g., `sonarqube-9.x.x.xxxx`).  For easier management and so the systemd service can find it, create a symbolic link:

    ```bash
    sudo ln -s /opt/sonarqube-* /opt/sonarqube  # Creates /opt/sonarqube as a link
    ```
    This way, regardless of the version number in the actual directory name, you'll always refer to it as `/opt/sonarqube`.

5.  **Create a SonarQube user:**

    ```bash
    sudo adduser --system --no-create-home --group --disabled-login sonarqube
    sudo chown -R sonarqube:sonarqube /opt/sonarqube
    ```

6.  **Configure SonarQube:** Edit the configuration file:

    ```bash
    sudo nano /opt/sonarqube/conf/sonar.properties
    ```

    Update these settings (replace `your_password` with the actual password you set for the `sonar` user in PostgreSQL):

    ```
    sonar.jdbc.username=sonar
    sonar.jdbc.password=your_password
    sonar.jdbc.url=jdbc:postgresql://localhost/sonar
    ```

7.  **Systemd Service:** Create a service file to manage SonarQube:

    ```bash
    sudo nano /etc/systemd/system/sonarqube.service
    ```

    Add this content:

    ```
    [Unit]
    Description=SonarQube service
    After=syslog.target network.target

    [Service]
    Type=forking
    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
    User=sonarqube
    Group=sonarqube
    Restart=always
    LimitNOFILE=65536
    LimitNPROC=4096

    [Install]
    WantedBy=multi-user.target
    ```

8.  **Start SonarQube:**

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl start sonarqube
    sudo systemctl enable sonarqube
    ```

9.  **Check Status:**

    ```bash
    sudo systemctl status sonarqube
    ```

## Important Notes

*   **File Descriptors:** Ensure the `sonarqube` user has enough file descriptors. Edit `/etc/security/limits.conf` and add:

    ```
    sonarqube - nofile 65536
    sonarqube - nproc 4096
    ```

*   **Virtual Memory:** Increase the virtual memory limit. Edit `/etc/sysctl.conf` and add:

    ```
    vm.max_map_count=262144
    ```

    Apply the changes:

    ```bash
    sudo sysctl -p
    ```

*   **Firewall:** Allow traffic on port 9000:

    ```bash
    sudo ufw allow 9000
    sudo ufw enable
    ```

*   **Troubleshooting:** Check the SonarQube logs in `/opt/sonarqube/logs` for any errors.
*   **Security:** Change the default PostgreSQL password and consider additional security measures for your SonarQube instance.

Remember to consult the official SonarQube documentation for the most up-to-date and detailed installation instructions.