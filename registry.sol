pragma solidity ^0.4.0;


contract Registry {
    mapping(bytes32 => bytes) names;
    mapping(bytes32 => address) transfers;
    mapping(bytes32 => Package) packages;

    address constant NULL = 0x0;

    struct Package {
        bytes32 name;
        address owner;
        uint8 latestMajor;
        mapping(uint8 => Major) majors;
    }

    struct Major {
        uint8 latestMinor; // Latest minor
        mapping(uint8 => Minor) minors;
    }

    struct Minor {
        uint16 latestBuild; // Latest build
        mapping(uint16 => Build) builds;
    }

    struct Build {
        bytes32 bzz;
        bool isPublished;
    }

    // Notify package version was publish
    event Published(bytes32 indexed package, uint8 indexed major, uint8 indexed minor, uint16 build);
    // Notify package version was unpublish
    event Unpublished(bytes32 indexed package, uint8 indexed major, uint8 indexed minor, uint16 build);
    // Package transfered to new owner
    event Transfered(bytes32 indexed package);

    // Register package name
    function register(bytes _name)
        public
        returns(bytes32)
    {
        require(_name.length > 0);

        bytes32 name = resolve(_name);
        require(packages[name].owner == NULL);

        packages[name] = Package(name, msg.sender, 0);
        names[name] = _name;

        return name;
    }

    // Resolve bytes name to hash
    function resolve(bytes _name)
      public
      pure
      returns(bytes32)
    {
      return keccak256(_name);
    }

    // Publish new version
    function publish(bytes32 _package, uint8 _major, uint8 _minor, uint16 _build, bytes32 _bzz)
        public
    {
        Package storage package = packages[_package];

        require(package.owner == msg.sender);
        require(hasBuild(_package, _major, _minor, _build) == false);

        package.majors[_major].minors[_minor].builds[_build] = Build(_bzz, true);

        Major memory major = package.majors[_major];
        Minor memory minor = package.majors[_major].minors[_minor];

        if (package.latestMajor < _major) {
            package.latestMajor = _major;
        }

        if (major.latestMinor < _minor) {
            package.majors[_major].latestMinor = _minor;
        }

        if (minor.latestBuild < _build) {
            package.majors[_major].minors[_minor].latestBuild = _build;
        }

        emit Published(_package, _major, _minor, _build);
    }

    // Unpublish version.
    function unpublish(bytes32 _package, uint8 _major, uint8 _minor, uint16 _build)
        public
    {
        Package storage package = packages[_package];

        require(msg.sender == package.owner);
        require(isPublished(_package, _major, _minor, _build));

        // Check if unpublished version is not the last one.
        uint8 major = getLatestMajorVersion(_package);

        if (major == _major) {
          uint8 minor = getLatestMinorVersion(_package, major);

          if (minor == _minor) {
            uint16 build = getLatestBuildVersion(_package, major, minor);

            require(build != _build);
          }
        }

        package.majors[_major].minors[_minor].builds[_build].isPublished = false;

        emit Unpublished(_package, _major, _minor, _build);
    }

    // Get build instance
    function getBuild(bytes32 _package, uint8 _major, uint8 _minor, uint16 _build)
        private
        view
        returns(Build)
    {
        return packages[_package].majors[_major].minors[_minor].builds[_build];
    }

    // Check is build exists.
    function hasBuild(bytes32 _package, uint8 _major, uint8 _minor, uint16 _build)
        public
        view
        returns(bool)
    {
        return getBuild(_package, _major, _minor, _build).bzz != '';
    }

    // Check is version exists.
    function isPublished(bytes32 _package, uint8 _major, uint8 _minor, uint16 _build)
        public
        view
        returns(bool)
    {
        return getBuild(_package, _major, _minor, _build).isPublished;
    }

    // Get latest published major version number.
    function getLatestMajorVersion(bytes32 _package)
        public
        constant
        returns(uint8)
    {
        return packages[_package].latestMajor;
    }

    // Get latest published minor version number.
    function getLatestMinorVersion(bytes32 _package, uint8 _major)
        public
        constant
        returns(uint8)
    {
        return packages[_package].majors[_major].latestMinor;
    }

    // Get latest published build version number.
    function getLatestBuildVersion(bytes32 _package, uint8 _major, uint8 _minor)
        public
        constant
        returns(uint16)
    {
        return packages[_package].majors[_major].minors[_minor].latestBuild;
    }

    // Get latest published major version number bzz address.
    function getLastestMajor(bytes32 _package)
        public
        constant
        returns(bytes32)
    {
        Package memory package = packages[_package];
        require(package.owner != NULL); // Package exists

        uint8 major = package.latestMajor;
        uint8 minor = packages[_package].majors[major].latestMinor;
        uint16 build = packages[_package].majors[major].minors[minor].latestBuild;

        return getBuild(_package, major, minor, build).bzz;
    }

    // Get latest published minor version bzz address.
    function getLatestMinor(bytes32 _package, uint8 _major)
        public
        constant
        returns(bytes32)
    {
        Package memory package = packages[_package];

        require(package.owner != NULL); // Package exists
        require(package.latestMajor <= _major); // Major exists

        uint8 minor = packages[_package].majors[_major].latestMinor;
        uint16 build = packages[_package].majors[_major].minors[minor].latestBuild;

        return getBuild(_package, _major, minor, build).bzz;
    }

    // Get latest published package build bzz address.
    function getLatestBuild(bytes32 _package, uint8 _major, uint8 _minor)
        public
        constant
        returns(bytes32)
    {
        Package memory package = packages[_package];

        require(package.owner != NULL); // Package exists
        require(package.latestMajor <= _major); // Major exists

        Major memory major = packages[_package].majors[_major];
        require(major.latestMinor <= _minor);

        uint16 build = packages[_package].majors[_major].minors[_minor].latestBuild;

        return getBuild(_package, _major, _minor, build).bzz;
    }

    // Get package owner address
    function getOwner(bytes32 _package)
        public
        constant
        returns(address)
    {
        return packages[_package].owner;
    }

    // Transfer package ownership
    function transfer(bytes32 _name, address newOwner)
        public
    {
        Package storage package = packages[_name];

        require(msg.sender == package.owner);

        transfers[_name] = newOwner;
    }

    // Accept ownership
    function receive(bytes32 _name)
        public
    {
        require(transfers[_name] != NULL);
        require(transfers[_name] == msg.sender);

        packages[_name].owner = msg.sender;
        transfers[_name] = NULL;

        emit Transfered(_name);
    }
}
