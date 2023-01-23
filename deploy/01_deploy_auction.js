const hre = require("hardhat");


const main = async function (hre) {
    const {deployments, getNamedAccounts} = hre;

    const {deployer} = await getNamedAccounts();
    const deployed = await hre.deployments.all();

    const POC = await hre.ethers.getContractFactory("POC");
    const poc = await POC.attach(deployed.POC.address);

    await deployments.deploy('POCDutchAuction', {
        from: deployer,
        args: [deployed.POC.address],
        log: true,
    });

    const beforeWhiteListed = await poc.isWhiteListed(deployed.POCDutchAuction.address);
    await poc.addWhiteLists(deployed.POCDutchAuction.address);
    const afterWhiteListed = await poc.isWhiteListed(deployed.POCDutchAuction.address);
    console.log(`Before : ${beforeWhiteListed}, After : ${afterWhiteListed}`);
};


module.exports = main;
main.tags = ["POCDutchAuction"];
