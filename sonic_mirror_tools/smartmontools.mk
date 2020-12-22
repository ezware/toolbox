include rules/smartmontools.mk

all:
	@echo "http://172.17.0.1/packages/debian/smartmontools_$(SMARTMONTOOLS_VERSION_MAJOR).orig.tar.gz?sv=2015-04-05&sr=b&sig=JZx4qiLuO36T0rsGqk4V2RDuWjRw6NztsLK7vlBYAkg%3D&se=2046-08-20T23%3A47%3A13Z&sp=r"
	@echo "http://172.17.0.1/packages/debian/smartmontools_$(SMARTMONTOOLS_VERSION_FULL).dsc?sv=2015-04-05&sr=b&sig=IS7FKUN%2Bvq0T55f4X2hGAViB70Y%2FgzjGgvzpUJLyUfA%3D&se=2046-08-20T23%3A46%3A57Z&sp=r"
	@echo "http://172.17.0.1/packages/debian/smartmontools_$(SMARTMONTOOLS_VERSION_FULL).debian.tar.xz?sv=2015-04-05&sr=b&sig=H0RFeC41MCvhTQCln85DuPLn5v2goozwz%2FB9sA9p5eQ%3D&se=2046-08-20T23%3A46%3A02Z&sp=r"
