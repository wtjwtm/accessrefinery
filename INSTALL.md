# Installation

- Prepare a Linux system (recommend [Ubuntu 22.04.5](https://releases.ubuntu.com/jammy/ubuntu-22.04.5-desktop-amd64.iso))

- Install JDK 17:

```bash
sudo apt install openjdk-17-jdk
```

Add Java to the environment variables (recommended):

```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
javac -version
java -version
```

Expected output:

```shell
javac 17.0.17
openjdk version "17.0.17" 2025-10-21
OpenJDK Runtime Environment (build 17.0.17+10-Ubuntu-122.04)
OpenJDK 64-Bit Server VM (build 17.0.17+10-Ubuntu-122.04, mixed mode, sharing)
```

- Install Maven:

```bash
sudo apt install maven
mvn -v
```

Expected output:

```shell
Apache Maven 3.6.3
Maven home: /usr/share/maven
Java version: 17.0.17, vendor: Ubuntu, runtime: /usr/lib/jvm/java-17-openjdk-amd64
Default locale: en_US, platform encoding: UTF-8
OS name: "linux", version: "6.8.0-90-generic", arch: "amd64", family: "unix"
```

- Install `gnuplot` for plotting figures:

```bash
sudo apt install gnuplot
gnuplot --version
```

Expected output:

```shell
gnuplot 5.4 patchlevel 2
```

## Build

In the root directory, run:

```bash
mvn clean package
```

The build generates the following JAR packages in `target/`:

- `mcp-1.0.jar` for *MCP*, which can be reused in other projects for fast multi-round SMT solving.
- `accessrefinery-1.0.jar` for *AccessRefinery*.
