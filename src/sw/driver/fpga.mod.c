#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x9a31bb74, "module_layout" },
	{ 0x6bc3fbc0, "__unregister_chrdev" },
	{ 0x5cd9dbb5, "kmalloc_caches" },
	{ 0xd2b09ce5, "__kmalloc" },
	{ 0xb3be75f6, "dev_set_drvdata" },
	{ 0xc8b57c27, "autoremove_wake_function" },
	{ 0x964bcb2, "boot_cpu_data" },
	{ 0x86db9a2d, "pci_disable_device" },
	{ 0xbafecf06, "remove_proc_entry" },
	{ 0x27e3ef6b, "device_destroy" },
	{ 0x6729d3df, "__get_user_4" },
	{ 0x9cc5adfc, "__register_chrdev" },
	{ 0x6efb8d26, "x86_dma_fallback_dev" },
	{ 0xe6959bc, "pci_release_regions" },
	{ 0x91715312, "sprintf" },
	{ 0xf432dd3d, "__init_waitqueue_head" },
	{ 0x4f8b5ddb, "_copy_to_user" },
	{ 0xd23f1d25, "proc_mkdir" },
	{ 0x64ce4311, "current_task" },
	{ 0x27e1a049, "printk" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0xd4f29297, "device_create" },
	{ 0x2072ee9b, "request_threaded_irq" },
	{ 0x3cf78bf4, "module_put" },
	{ 0xb2fd5ceb, "__put_user_4" },
	{ 0x42c8de35, "ioremap_nocache" },
	{ 0xf0fdf6cb, "__stack_chk_fail" },
	{ 0xd62c833f, "schedule_timeout" },
	{ 0x57a0725b, "create_proc_entry" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0xf55bb238, "pci_unregister_driver" },
	{ 0xd61adcbd, "kmem_cache_alloc_trace" },
	{ 0xe52947e7, "__phys_addr" },
	{ 0xcf21d241, "__wake_up" },
	{ 0x37a0cba, "kfree" },
	{ 0x1ac46550, "remap_pfn_range" },
	{ 0x2252cdbc, "pci_request_regions" },
	{ 0x5c8b5ce8, "prepare_to_wait" },
	{ 0x17e6fdf7, "pci_disable_msi" },
	{ 0xedc03953, "iounmap" },
	{ 0xaba33759, "__pci_register_driver" },
	{ 0xf3248a6e, "class_destroy" },
	{ 0xfa66f77c, "finish_wait" },
	{ 0x28318305, "snprintf" },
	{ 0x8a6c7bfe, "pci_enable_msi_block" },
	{ 0xace5f3c3, "pci_enable_device" },
	{ 0x4f6b400b, "_copy_from_user" },
	{ 0x25827ecd, "__class_create" },
	{ 0x10519fe3, "dev_get_drvdata" },
	{ 0xc6849b4a, "dma_ops" },
	{ 0x94993346, "try_module_get" },
	{ 0xf20dabd8, "free_irq" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";


MODULE_INFO(srcversion, "F24E09A2974030A7CEB8B63");
