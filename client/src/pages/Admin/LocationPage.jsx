import React, { useEffect, useState } from 'react';
import { Layout, Table, Button, Space, Modal, Form, Input, Select, message } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';

const { Content } = Layout;
const { Option } = Select;

const LocationPage = () => {
  const [cities, setCities] = useState([]);
  const [districts, setDistricts] = useState([]);
  const [wards, setWards] = useState([]);
  const [selectedLocationType, setSelectedLocationType] = useState('city'); // 'city', 'district', 'ward'
  const [modal, setModal] = useState({ open: false, edit: null });
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(true);

  // Fetch data
  const fetchData = async () => {
    setLoading(true);
    try {
      const [citiesRes, districtsRes, wardsRes] = await Promise.all([
        axiosPrivate.get('/api/admin/cities'),
        axiosPrivate.get('/api/admin/districts'),
        axiosPrivate.get('/api/admin/wards'),
      ]);
      const citiesData = unwrapListResponse(citiesRes);
      const districtsData = unwrapListResponse(districtsRes);
      const wardsData = unwrapListResponse(wardsRes);
      setCities(citiesData);
      setDistricts(districtsData);
      setWards(wardsData);
    } catch (error) {
      console.error('Error fetching location data:', error);
      const errorData = error.response?.data;
      const errorMessage = errorData?.message || errorData || 'Lỗi khi tải dữ liệu';
      message.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Modal open/close
  const handleAdd = (type) => {
    setSelectedLocationType(type);
    setModal({ open: true, edit: null });
    form.resetFields();
  };

  const handleEdit = (type, record) => {
    setSelectedLocationType(type);
    setModal({ open: true, edit: record });
    if (type === 'city') {
      form.setFieldsValue({ name: record.name });
    } else if (type === 'district') {
      form.setFieldsValue({ name: record.name, cityId: record.cityId });
    } else if (type === 'ward') {
      form.setFieldsValue({ name: record.name, districtId: record.districtId });
    }
  };

  const handleDelete = async (id, type) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa?')) {
      try {
        let response;
        if (type === 'city') {
          response = await axiosPrivate.delete(`/api/admin/cities/${id}`);
        } else if (type === 'district') {
          response = await axiosPrivate.delete(`/api/admin/districts/${id}`);
        } else if (type === 'ward') {
          response = await axiosPrivate.delete(`/api/admin/wards/${id}`);
        }
        
        if (response?.status === 200 || response?.status === 204) {
          message.success('Đã xóa thành công');
          fetchData();
        }
      } catch (error) {
        console.error('Error deleting location:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Lỗi khi xóa';
        message.error(errorMessage);
      }
    }
  };

  // Modal OK
  const handleOk = async () => {
    try {
      const values = await form.validateFields();
      let response;
      
      if (modal.edit) {
        // Edit
        if (selectedLocationType === 'city') {
          response = await axiosPrivate.put(`/api/admin/cities/${modal.edit.id}`, { 
            id: modal.edit.id, 
            name: values.name 
          });
        } else if (selectedLocationType === 'district') {
          response = await axiosPrivate.put(`/api/admin/areas/districts/${modal.edit.id}`, { 
            name: values.name, 
            cityId: values.cityId 
          });
        } else if (selectedLocationType === 'ward') {
          response = await axiosPrivate.put(`/api/admin/areas/wards/${modal.edit.id}`, { 
            name: values.name, 
            districtId: values.districtId 
          });
        }
        message.success('Cập nhật thành công');
      } else {
        // Add
        if (selectedLocationType === 'city') {
          response = await axiosPrivate.post('/api/admin/cities', { name: values.name });
        } else if (selectedLocationType === 'district') {
          response = await axiosPrivate.post('/api/admin/districts', { 
            name: values.name, 
            cityId: values.cityId 
          });
        } else if (selectedLocationType === 'ward') {
          response = await axiosPrivate.post('/api/admin/wards', { 
            name: values.name, 
            districtId: values.districtId 
          });
        }
        message.success('Thêm mới thành công');
      }
      
      setModal({ open: false, edit: null });
      form.resetFields();
      fetchData();
    } catch (error) {
      console.error('Error in location operation:', error);
      const errorData = error.response?.data;
      const errorMessage = errorData?.message || errorData || 'Lỗi khi thao tác';
      message.error(errorMessage);
    }
  };

  // Table columns
  const cityColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id' },
    { title: 'Tên thành phố', dataIndex: 'name', key: 'name' },
    {
      title: 'Hành động',
      key: 'action',
      render: (_, record) => (
        <Space>
          <Button type="primary" onClick={() => handleEdit('city', record)}>Sửa</Button>
          <Button danger onClick={() => handleDelete(record.id, 'city')}>Xóa</Button>
        </Space>
      ),
    },
  ];

  const districtColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 80 },
    { title: 'Tên quận/huyện', dataIndex: 'name', key: 'name' },
    { 
      title: 'Thành phố', 
      dataIndex: 'cityId', 
      key: 'city',
      render: (cityId) => {
        const city = cities.find(c => c.id === cityId);
        return city ? city.name : cityId;
      }
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 150,
      render: (_, record) => (
        <Space>
          <Button type="primary" onClick={() => handleEdit('district', record)}>Sửa</Button>
          <Button danger onClick={() => handleDelete(record.id, 'district')}>Xóa</Button>
        </Space>
      ),
    },
  ];

  const wardColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 80 },
    { title: 'Tên phường/xã', dataIndex: 'name', key: 'name' },
    { 
      title: 'Quận/Huyện', 
      dataIndex: 'districtId', 
      key: 'district',
      render: (districtId) => {
        const district = districts.find(d => d.id === districtId);
        return district ? district.name : districtId;
      }
    },
    { 
      title: 'Thành phố', 
      dataIndex: 'districtId', 
      key: 'city',
      render: (districtId) => {
        const district = districts.find(d => d.id === districtId);
        if (district) {
          const city = cities.find(c => c.id === district.cityId);
          return city ? city.name : '';
        }
        return '';
      }
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 150,
      render: (_, record) => (
        <Space>
          <Button type="primary" onClick={() => handleEdit('ward', record)}>Sửa</Button>
          <Button danger onClick={() => handleDelete(record.id, 'ward')}>Xóa</Button>
        </Space>
      ),
    },
  ];

  // Render table by selectedLocationType
  const renderTable = () => {
    if (selectedLocationType === 'city') {
      return <Table columns={cityColumns} dataSource={cities} loading={loading} rowKey="id" />;
    }
    if (selectedLocationType === 'district') {
      return <Table columns={districtColumns} dataSource={districts} loading={loading} rowKey="id" />;
    }
    if (selectedLocationType === 'ward') {
      return <Table columns={wardColumns} dataSource={wards} loading={loading} rowKey="id" />;
    }
    return null;
  };

  // Modal form fields
  const renderFormFields = () => {
    if (selectedLocationType === 'city') {
      return (
        <Form.Item name="name" label="Tên thành phố" rules={[{ required: true, message: 'Nhập tên thành phố' }]}>
          <Input />
        </Form.Item>
      );
    }
    if (selectedLocationType === 'district') {
      return (
        <>
          <Form.Item name="name" label="Tên quận/huyện" rules={[{ required: true, message: 'Nhập tên quận/huyện' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="cityId" label="Thành phố" rules={[{ required: true, message: 'Chọn thành phố' }]}>
            <Select>
              {cities.map(city => (
                <Option key={city.id} value={city.id}>{city.name}</Option>
              ))}
            </Select>
          </Form.Item>
        </>
      );
    }
    if (selectedLocationType === 'ward') {
      return (
        <>
          <Form.Item name="name" label="Tên phường/xã" rules={[{ required: true, message: 'Nhập tên phường/xã' }]}>
            <Input />
          </Form.Item>
          <Form.Item name="districtId" label="Quận/Huyện" rules={[{ required: true, message: 'Chọn quận/huyện' }]}>
            <Select 
              showSearch
              placeholder="Chọn quận/huyện"
              filterOption={(input, option) =>
                (option?.children ?? '').toLowerCase().includes(input.toLowerCase())
              }
            >
              {districts.map(district => {
                const city = cities.find(c => c.id === district.cityId);
                return (
                  <Option key={district.id} value={district.id}>
                    {district.name} {city ? `- ${city.name}` : ''}
                  </Option>
                );
              })}
            </Select>
          </Form.Item>
        </>
      );
    }
    return null;
  };

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sidebar selectedKey="/admin/locations" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý địa điểm</h1>
          <Space style={{ marginBottom: 16 }}>
            <Button type={selectedLocationType === 'city' ? 'primary' : 'default'} onClick={() => setSelectedLocationType('city')}>Thành phố</Button>
            <Button type={selectedLocationType === 'district' ? 'primary' : 'default'} onClick={() => setSelectedLocationType('district')}>Quận/Huyện</Button>
            <Button type={selectedLocationType === 'ward' ? 'primary' : 'default'} onClick={() => setSelectedLocationType('ward')}>Phường/Xã</Button>
            <Button type="primary" onClick={() => handleAdd(selectedLocationType)}>Thêm {selectedLocationType === 'city' ? 'thành phố' : selectedLocationType === 'district' ? 'quận/huyện' : 'phường/xã'}</Button>
          </Space>
          {renderTable()}
          <Modal
            open={modal.open}
            onCancel={() => { setModal({ open: false, edit: null }); form.resetFields(); }}
            onOk={handleOk}
            title={
              modal.edit
                ? selectedLocationType === 'city'
                  ? 'Sửa thành phố'
                  : selectedLocationType === 'district'
                  ? 'Sửa quận/huyện'
                  : 'Sửa phường/xã'
                : selectedLocationType === 'city'
                ? 'Thêm thành phố mới'
                : selectedLocationType === 'district'
                ? 'Thêm quận/huyện mới'
                : 'Thêm phường/xã mới'
            }
            okText={modal.edit ? 'Cập nhật' : 'Thêm'}
          >
            <Form form={form} layout="vertical">
              {renderFormFields()}
            </Form>
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default LocationPage;

