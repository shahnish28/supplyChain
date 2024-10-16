// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SupplyChain {
    enum State { Manufactured, Shipped, ForSale, Sold }

    struct Product {
        uint productId;
        string name;
        uint price;
        State state; // This declares a state variable of type State.
        address manufacturer;
        address currentOwner;
        address[] owners; // This is a dynamic array type that holds multiple elements of type address.
    }

    mapping(uint => Product) public products;
    uint public productCounter;

    modifier onlyManufacturer(uint _productId) {
        require(msg.sender == products[_productId].manufacturer, "Only the manufacturer can perform this action");
        _; // Inserts the function logic here.
    }    

    modifier onlyOwner(uint _productId) {
        require(msg.sender == products[_productId].currentOwner, "Only the owner can perform this action");
        _; // Inserts the function logic here.
    }

    event ProductManufactured(uint productId, string name, address manufacturer);
    event ProductShipped(uint productId, address from, address to);
    event ProductForSale(uint productId, uint price);
    event ProductSold(uint productId, address from, address to, uint price);

    // Step 1: Manufacturer adds a product 
    function manufactureProduct(string memory _name, uint _price) public {
        productCounter++;
        Product storage newProduct = products[productCounter];
        newProduct.productId = productCounter;
        newProduct.name = _name;
        newProduct.price = _price;
        newProduct.state = State.Manufactured;
        newProduct.manufacturer = msg.sender;
        newProduct.currentOwner = msg.sender;
        newProduct.owners.push(msg.sender);

        emit ProductManufactured(productCounter, _name, msg.sender);
    } 

    // Step 2: Manufacturer ships the product to distributor/retailer
    function shipProduct(uint _productId, address _to) public onlyOwner(_productId) {
        require(products[_productId].state == State.Manufactured, "Product not in Manufactured state");
        
        products[_productId].state = State.Shipped;
        products[_productId].currentOwner = _to;
        products[_productId].owners.push(_to);

        emit ProductShipped(_productId, msg.sender, _to);
    }

    // step3 : retailer puts the product for sale
    function putforsale(uint _productId,uint _price) public onlyOwner(_productId) {
        require(products[_productId].state== State.Shipped,"product not ready for sale");
        products[_productId].state = State.ForSale;
        products[_productId].price = _price;

        emit ProductForSale(_productId, _price);

    }

    function buyProduct(uint _productId) public payable {
        require(products[_productId].state == State.ForSale, "Product not for sale");
        require(msg.value >= products[_productId].price, "Insufficient payment");

        products[_productId].state = State.Sold;
        products[_productId].currentOwner = msg.sender;
        products[_productId].owners.push(msg.sender);

        // Transfer the payment to the seller
        payable(products[_productId].owners[products[_productId].owners.length - 2]).transfer(msg.value);

        emit ProductSold(_productId, products[_productId].owners[products[_productId].owners.length - 2], msg.sender, msg.value);
    }

    // View product history (who owned the product)
    function viewProductHistory(uint _productId) public view returns (address[] memory) {
        return products[_productId].owners;
    }
}
